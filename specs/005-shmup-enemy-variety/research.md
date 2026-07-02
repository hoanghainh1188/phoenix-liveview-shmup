# Phase 0 Research: Đa dạng địch và Boss (005)

## 1. Chọn loại địch thường tất định

**Decision**: `Enemies.pick_kind(tier, id)`:
- Nếu `tier < tank_min_tier()` (mặc định 2) → luôn `:grunt`.
- Ngược lại, `roll = rem(id * @kind_hash_multiplier, 100)`; nếu `roll < tank_chance_pct(tier)` → `:tank`, ngược lại `:grunt`.

Dùng hằng số nhân **khác** với `@drop_hash_multiplier` của `Powerups` (003) để tránh kết quả hai hệ thống bị tương quan giả (cùng một `id` không nên luôn "trúng" hoặc luôn "trượt" ở cả hai phép băm).

**Rationale**: Nhất quán với mẫu tất định đã dùng cho powerup — không dùng `:rand`, dễ viết test với `id` cụ thể cho kết quả biết trước.

**Alternatives considered**:

- Chọn kind theo `rem(tier, N)` cố định (không phụ thuộc `id`) — dễ đoán quá mức, mọi địch cùng tier sẽ cùng loại, không tạo cảm giác "xen kẽ" như spec yêu cầu.

---

## 2. Chỉ số `:tank` so với `:grunt`

**Decision**: `:tank` dùng lại `Difficulty.enemy_hp(tier)` làm hp cơ sở rồi nhân `Enemies.tank_hp_multiplier()` (mặc định `3`), `vy` nhân `Enemies.tank_speed_multiplier()` (mặc định `0.5`), kích thước `w`/`h` nhân `Enemies.tank_size_multiplier()` (mặc định `1.4`, làm tròn). Quỹ đạo (`movement`) vẫn dùng `movement_for_tier/2` như hiện tại — không cần chế độ chuyển động riêng.

**Rationale**: Tái dùng nguyên bảng `Difficulty` đã có (002) làm nền, chỉ nhân hệ số theo `kind` — không cần bảng tham số hp/tốc độ riêng biệt cho tank theo từng tier, giảm số tham số cần tinh chỉnh.

**Alternatives considered**:

- Bảng hp/tốc độ tank độc lập theo tier (không liên hệ `Difficulty`) — chính xác hơn về mặt cân bằng nhưng tăng số tham số phải đồng bộ mỗi khi chỉnh `Difficulty`; hệ số nhân đơn giản hơn và đủ cho MVP.

---

## 3. Mốc tier sinh boss và theo dõi trạng thái

**Decision**: `Enemies.boss_tier_interval()` mặc định `5`. `GameState` thêm `next_boss_tier`, khởi tạo `Enemies.boss_tier_interval()` trong `new_playing/0`. Sau bước `advance_play_time/1` (nơi `difficulty_tier` được cập nhật), một stage mới `maybe_spawn_boss/1` kiểm tra `s.difficulty_tier >= s.next_boss_tier`; nếu đúng, sinh boss và đặt `next_boss_tier = next_boss_tier + boss_tier_interval()`.

**Rationale**: Mốc tuyệt đối tăng dần (giống mẫu `expires_at_tick` ở 003/004) đơn giản hơn đếm ngược, và tự nhiên đảm bảo "mỗi mốc chỉ một boss" — kể cả nếu tier nhảy nhiều hơn 1 trong tương lai, `while`-style kiểm tra lại `>=` (không phải `==`) vẫn đúng, tránh bỏ sót mốc theo đúng edge case đã ghi trong spec.

**Alternatives considered**:

- Trigger sinh boss ngay tại thời điểm tier tăng (trong `advance_play_time/1`) thay vì stage riêng — gộp logic không liên quan vào một hàm, khó test độc lập hơn; tách stage riêng rõ ràng hơn.

---

## 4. Boss có được vượt `max_enemies(tier)` không?

**Decision**: **Có, đúng một lần tại tick sinh boss.** `maybe_spawn_boss/1` sinh boss vô điều kiện khi đạt mốc, bất kể `length(s.enemies)` so với `Difficulty.max_enemies(tier)`. Mọi spawn thường khác (`maybe_spawn_enemy/1`) vẫn tuân thủ trần như cũ.

**Rationale**: SC-003 yêu cầu "đúng 1 boss xuất hiện, không phải 0" tại mỗi mốc — nếu để trần chặn boss khi màn hình đông địch, boss có thể không bao giờ xuất hiện ở tier cao (khi `max_enemies` gần đạt thường xuyên), vi phạm success criteria. Vượt trần tối đa 1 địch tại đúng thời điểm đó có tác động hiệu năng không đáng kể.

**Alternatives considered**:

- Chặn spawn thường một tick để "nhường chỗ" cho boss — phức tạp hơn không cần thiết, và vẫn có thể trượt mốc nếu điều kiện nhường chỗ không khớp thời điểm.

---

## 5. Máu và điểm thưởng boss

**Decision**: `boss_hp = Difficulty.enemy_hp(tier) * Enemies.boss_hp_multiplier()` (mặc định hệ số `15`) — tính tại **thời điểm sinh boss** theo tier hiện tại, không cố định tuyệt đối, để boss ở mốc tier cao vẫn đủ thử thách. Kích thước cố định lớn hơn hẳn (ví dụ `w: 90, h: 70` so với grunt `32x28`). Điểm thưởng: **cộng thêm** `Enemies.boss_bonus_points()` (mặc định `240`) vào điểm giết cơ bản đã có (`@points_per_kill = 10` không đổi trong `Collision`), tính riêng trong `Simulation.resolve_hits/1` từ danh sách `killed` — **không đổi API `Collision.resolve_player_bullets_vs_enemies/3`**, tránh phá vỡ test hiện có của 001–004.

**Rationale**: Tách điểm thưởng boss ra khỏi `Collision` giữ thay đổi API bằng 0 cho hàm cốt lõi đã ổn định qua 4 feature trước — giảm rủi ro hồi quy. Việc tính hp theo tier tại thời điểm sinh (thay vì hằng số tuyệt đối) giữ boss luôn "đáng gờm" tương xứng với độ khó hiện tại.

**Alternatives considered**:

- Đổi `Collision.resolve_player_bullets_vs_enemies/3` nhận hàm `score_fn` thay vì số nguyên cố định — thiết kế "đúng" hơn về lâu dài, nhưng phá vỡ chữ ký hàm và toàn bộ test hiện có của `CollisionTest` (001–004); cộng dồn bonus riêng trong `Simulation` đạt cùng hiệu quả với thay đổi tối thiểu.

---

## 6. Phân biệt trực quan theo `kind`

**Decision**: Thêm `:kind` vào `@enemy_snapshot_keys` trong `GameLive.snapshot/1` (an toàn JSON vì atom encode thành string, không phải tuple — cùng nguyên tắc đã ghi trong `CLAUDE.md`). `game_hook.js` map màu theo kind: `grunt: "#a78bfa"` (tím, như hiện tại), `tank: "#f97316"` (cam), `boss: "#ef4444"` (đỏ nổi bật) — kích thước đã khác nhau sẵn từ dữ liệu server (`w`/`h` gửi kèm mỗi enemy), không cần client tự suy luận kích thước.

**Rationale**: Tái dùng cơ chế `drawBox` hiện có, chỉ đổi màu theo `kind` — không cần asset/sprite mới, nhất quán với phong cách "hộp màu" hiện tại của toàn bộ canvas.

---

## 7. Reset ván mới

**Decision**: `GameState.new_playing/0` đặt `next_boss_tier: Enemies.boss_tier_interval()` — đúng nguyên tắc đã áp dụng cho mọi trạng thái theo dõi tiến trình khác (powerup active_effects ở 003, hp/invulnerable_until ở 004).

**Rationale**: Đảm bảo FR-008 — ván mới luôn cho boss xuất hiện lại đúng từ mốc đầu tiên.

---

## 8. Bảng tham số (`Enemies` module, giống vai trò `Difficulty`/`Powerups`/`Health`)

| Tham số | Giá trị MVP | Ghi chú |
|---|---|---|
| `tank_min_tier` | 2 | Tier tối thiểu để `:tank` bắt đầu có thể xuất hiện |
| `tank_chance_pct` | 30 | % cơ hội một địch thường (từ tier đủ điều kiện) là `:tank` |
| `tank_hp_multiplier` | 3 | Hệ số nhân hp so với `:grunt` cùng tier |
| `tank_speed_multiplier` | 0.5 | Hệ số nhân `vy` (chậm hơn) |
| `tank_size_multiplier` | 1.4 | Hệ số nhân `w`/`h` |
| `boss_tier_interval` | 5 | Sinh boss mỗi N tier |
| `boss_hp_multiplier` | 15 | Hệ số nhân hp so với `Difficulty.enemy_hp(tier)` tại thời điểm sinh |
| `boss_bonus_points` | 240 | Điểm thưởng cộng thêm khi hạ boss (ngoài điểm giết cơ bản 10) |
| `boss_width` / `boss_height` | 90 / 70 | Kích thước cố định, lớn hơn hẳn grunt (32×28) |

**Rationale**: Tách bảng tham số khỏi `Simulation`, đúng tiền lệ ba module trước — dễ tinh chỉnh cân bằng mà không sửa pipeline.
