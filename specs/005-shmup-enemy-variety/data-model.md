# Data Model: Đa dạng địch và Boss (005)

Mở rộng mô hình logical trong [001](../001-shmup-start-gameplay/data-model.md), [002](../002-shmup-difficulty-waves/data-model.md), [003](../003-shmup-powerups/data-model.md), [004](../004-shmup-player-health/data-model.md). Trạng thái vẫn **authoritative** trên server; JSON snapshot cho hook là **projection**.

## State machine

Không đổi: `:splash` | `:playing` | `:game_over`.

## `GameState` — trường bổ sung

| Field | Type / notes |
|-------|----------------|
| `next_boss_tier` | Số nguyên ≥ 1; mốc `difficulty_tier` tiếp theo sẽ sinh boss. Khởi tạo `Enemies.boss_tier_interval()`, tăng thêm cùng giá trị đó sau mỗi lần sinh boss. |

## `Enemy` — trường bổ sung

| Field | Description |
|-------|-------------|
| `kind` | Atom: `:grunt` (mặc định, hành vi như 001/002) \| `:tank` (hp/kích thước lớn hơn, chậm hơn) \| `:boss` (mốc tier định kỳ, vượt trội, điểm thưởng lớn). |

`x`, `y`, `w`, `h`, `vy`, `vx`, `movement`, `hp`, `id` không đổi cấu trúc — chỉ giá trị khởi tạo phụ thuộc thêm vào `kind`.

## Sinh địch thường (mở rộng `spawn_one_enemy/1`)

1. Tính `kind = Enemies.pick_kind(tier, id)` (xem `research.md` §1).
2. Với `kind == :grunt`: hp/kích thước/tốc độ như hiện có (không đổi).
3. Với `kind == :tank`: `hp = round(Difficulty.enemy_hp(tier) * Enemies.tank_hp_multiplier())`, `vy = base_vy * Enemies.tank_speed_multiplier()`, `w`/`h` nhân `Enemies.tank_size_multiplier()` (làm tròn).
4. `movement` chọn theo `movement_for_tier/2` như cũ cho cả hai kind, không đổi.

## Sinh boss (mới, `maybe_spawn_boss/1`)

- Điều kiện: `state.difficulty_tier >= state.next_boss_tier`.
- Khi đúng: thêm một enemy mới với `kind: :boss`, `id: state.next_id`, `x: state.width / 2` (giữa màn hình), `y: 30.0`, `w: Enemies.boss_width()`, `h: Enemies.boss_height()`, `hp: round(Difficulty.enemy_hp(tier) * Enemies.boss_hp_multiplier())`, `movement` chọn theo `movement_for_tier/2` như địch thường.
- **Không** bị chặn bởi `Difficulty.max_enemies(tier)` (xem `research.md` §4 — ngoại lệ có chủ đích, chỉ áp dụng cho boss).
- Sau khi sinh: `next_boss_tier = next_boss_tier + Enemies.boss_tier_interval()`.
- `next_id` tăng như spawn thường (boss dùng chung bộ đếm id với grunt/tank).

## Tính điểm khi hạ địch (mở rộng `resolve_hits/1`, không đổi `Collision`)

- Điểm cơ bản mỗi lần hạ (`@points_per_kill = 10`) tính như hiện có qua `Collision.resolve_player_bullets_vs_enemies/3` — **không đổi**, áp dụng đều cho mọi `kind`.
- Điểm thưởng bổ sung: với mỗi enemy trong `killed` có `kind == :boss`, cộng thêm `Enemies.boss_bonus_points()` vào `state.score`, tính **sau** khi điểm cơ bản đã cộng.
- Tổng điểm khi hạ boss = `@points_per_kill + Enemies.boss_bonus_points()` (mặc định `10 + 240 = 250`).

## Khởi tạo ván mới (`GameState.new_playing/0`)

- `next_boss_tier: Enemies.boss_tier_interval()`.
- Đảm bảo FR-008: không kế thừa mốc boss đã sinh từ ván trước — ván mới luôn có thể sinh boss lại đúng từ mốc đầu tiên.

## Validation / biên

- `next_boss_tier` luôn tăng dần, không bao giờ giảm hoặc đứng yên sau khi một boss được sinh.
- Tổng số địch trên màn hình có thể vượt `Difficulty.max_enemies(tier)` đúng **tối đa 1** (do boss), chỉ tại tick sinh boss — không tích luỹ thêm ở các tick sau (vì `maybe_spawn_enemy/1` vẫn tôn trọng trần cho mọi spawn tiếp theo).
- `kind` chỉ nhận một trong ba giá trị hợp lệ; không có địch nào thiếu `kind` sau khi feature này bật (kể cả trong test cũ dùng `static_enemy/2` — cần bổ sung `kind: :grunt` mặc định để không phá vỡ test hiện có tham chiếu `enemy.kind`).

## Snapshot JSON (`frame`) — trường bổ sung

| Field | Ghi chú |
|-------|---------|
| `enemies[].kind` | String sau khi Jason encode atom (`"grunt"` \| `"tank"` \| `"boss"`); thêm vào `@enemy_snapshot_keys` trong `GameLive.snapshot/1`, không phải tuple nên an toàn JSON theo nguyên tắc hiện có. |

Hook bỏ qua field này an toàn nếu client cũ chưa xử lý (vẽ mặc định như trước).
