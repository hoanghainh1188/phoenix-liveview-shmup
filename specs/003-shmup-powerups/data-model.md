# Data Model: Power-up và vũ khí nâng cấp (003)

Mở rộng mô hình logical trong [001](../001-shmup-start-gameplay/data-model.md) và [002](../002-shmup-difficulty-waves/data-model.md). Trạng thái vẫn **authoritative** trên server; JSON snapshot cho hook là **projection**.

## State machine

Không đổi: `:splash` | `:playing` | `:game_over`.

## `GameState` — trường bổ sung

| Field | Type / notes |
|-------|----------------|
| `powerups` | `[Powerup.t()]`; danh sách vật phẩm đang rơi trên màn hình, mới nhất ở đầu (giống quy ước `enemies`). |
| `next_powerup_id` | Số nguyên ≥ 1; id tăng dần cho powerup mới, độc lập với `next_id` của enemy. |

## `Powerup` — cấu trúc mới

| Field | Description |
|-------|-------------|
| `id` | Số nguyên ổn định, dùng để debug/test và (tuỳ chọn) key trong client. |
| `x`, `y`, `w`, `h` | Hitbox AABB tâm + kích thước, cùng quy ước với enemy/bullet hiện có. |
| `vy` | Vận tốc rơi (hằng số từ `Powerups.fall_speed/0`). |
| `kind` | Atom: `:rapid_fire` \| `:multi_shot` \| `:shield`. |

## `Player` — trường bổ sung

| Field | Description |
|-------|-------------|
| `active_effects` | Map từ atom kind (`:rapid_fire`, `:multi_shot`) tới `expires_at_tick` (số nguyên, mốc `play_tick` tuyệt đối). Key vắng mặt nghĩa là hiệu lực đó không hoạt động. Không chứa `:shield` (xem field riêng bên dưới). |
| `shield` | Boolean; `true` nếu khiên đang hoạt động (đã nhặt, chưa hấp thụ đòn nào, chưa hết hạn). |
| `shield_expires_at` | Số nguyên hoặc `nil`; mốc `play_tick` khiên tự hết hạn nếu không bị dùng tới. `nil` khi `shield == false`. |

`x`, `y`, `w`, `h` của player không đổi.

## Va chạm — mở rộng luật hiện có

- **Player vs Powerup**: `aabb_overlap?(player, powerup)` (tái dùng `Collision.aabb_overlap?/2`). Khi trúng: powerup bị loại khỏi `powerups`; hiệu lực tương ứng được áp dụng lên `player` theo luật ở mục "Kích hoạt hiệu lực" bên dưới.
- **Enemy bullet vs Player (mở rộng luật một-hit-chết)**:
  - Nếu `player.shield == true`: viên đạn bị tiêu thụ (loại khỏi `enemy_bullets`), `player.shield` chuyển `false`, `player.shield_expires_at` chuyển `nil`, **không** chuyển `phase` sang `:game_over`.
  - Nếu `player.shield == false`: hành vi không đổi so với 001/002 — trúng đạn ⇒ `GameState.new_game_over/1`.

## Kích hoạt hiệu lực khi nhặt (`kind` của powerup vừa nhặt)

| `kind` | Hiệu ứng khi nhặt |
|---|---|
| `:rapid_fire` | `active_effects[:rapid_fire] = play_tick + Powerups.rapid_fire_duration_ticks()` (gán lại, không cộng dồn — xem research §3). |
| `:multi_shot` | `active_effects[:multi_shot] = play_tick + Powerups.multi_shot_duration_ticks()` (gán lại). |
| `:shield` | `shield = true`, `shield_expires_at = play_tick + Powerups.shield_duration_ticks()` (gán lại nếu đã có khiên — gia hạn thời gian, không xếp chồng "hai khiên"). |

## Hết hạn mỗi tick (`Simulation.step/1`, chạy khi `:playing`)

- Với mỗi `kind` trong `active_effects`: nếu `expires_at_tick <= play_tick`, xóa key khỏi map.
- Nếu `shield == true` và `shield_expires_at <= play_tick`: `shield = false`, `shield_expires_at = nil` (hết hạn do không dùng tới, khác với tiêu hao do đỡ đạn).

## Bắn đạn — phụ thuộc hiệu lực (mở rộng `fire_player_bullet/1`)

- **Cooldown**: `if Map.has_key?(active_effects, :rapid_fire), do: Powerups.rapid_fire_cooldown_ticks(), else: @player_fire_cooldown`.
- **Số viên đạn / hướng**: `if Map.has_key?(active_effects, :multi_shot)`, sinh `Powerups.multi_shot_bullet_count()` viên với `vx` lệch đối xứng quanh 0 (ví dụ `[-2.5, 0.0, 2.5]` cho 3 viên), còn lại `vy` như đạn cơ bản; ngược lại sinh 1 viên như hiện tại (`vx` mặc định 0).

## Spawn powerup khi hạ địch (mở rộng `resolve_hits/1`)

- Chỉ xét khi một enemy **thực sự bị hạ** (`hp` về ≤ 0 trong cùng lượt trừ máu), không xét khi enemy chỉ bị trừ hp mà còn sống.
- Tính tất định từ `enemy.id` (xem research §1); nếu đạt ngưỡng rơi **và** `length(powerups) < Powerups.max_falling_powerups()`, thêm một `Powerup` mới tại vị trí enemy vừa hạ, `next_powerup_id` tăng.
- Nếu đã đạt `max_falling_powerups`, bỏ qua lượt rơi đó (không xếp hàng chờ) — giữ đơn giản cho MVP.

## Dọn dẹp ngoài màn hình (mở rộng `cull_offscreen/1`)

- `powerups` bị lọc theo cùng ngưỡng `y < h + 80` như enemy (rơi khỏi đáy màn hình thì biến mất, không có hiệu lực).

## Khởi tạo ván mới (`GameState.new_playing/0`)

- `powerups: []`, `next_powerup_id: 1`.
- `player.active_effects: %{}`, `player.shield: false`, `player.shield_expires_at: nil`.
- Đảm bảo FR-009: không kế thừa bất kỳ hiệu lực nào từ ván trước vì `new_playing/0` luôn tạo player mới hoàn toàn.

## Validation / biên

- `active_effects` chỉ chứa 2 key khả dĩ (`:rapid_fire`, `:multi_shot`); không có atom lạ.
- `length(powerups) <= Powerups.max_falling_powerups()` tại mọi thời điểm sau một bước `Simulation.step/1`.
- `shield` và `shield_expires_at` luôn đồng bộ (`shield == false` ⇔ `shield_expires_at == nil`).

## Snapshot JSON (`frame`) — trường bổ sung

| Field | Ghi chú |
|-------|---------|
| `powerups` | Danh sách `%{id, x, y, w, h, kind}`; `kind` là atom nhưng Jason encode được thành string, không phải tuple — an toàn theo quy tắc JSON-safe hiện có. |
| `player_effects` | `%{rapid_fire: boolean, multi_shot: boolean, shield: boolean}` — cờ hiện diện rút gọn từ `active_effects`/`shield`, **không** gửi `expires_at_tick` tuyệt đối (chi tiết nội bộ, không cần cho client). |

Hook có thể bỏ qua các field mới nếu chưa vẽ UI powerup/HUD hiệu lực.
