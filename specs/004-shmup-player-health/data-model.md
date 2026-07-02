# Data Model: Máu/mạng người chơi (004)

Mở rộng mô hình logical trong [001](../001-shmup-start-gameplay/data-model.md), [002](../002-shmup-difficulty-waves/data-model.md), [003](../003-shmup-powerups/data-model.md). Trạng thái vẫn **authoritative** trên server; JSON snapshot cho hook là **projection**.

## State machine

Không đổi: `:splash` | `:playing` | `:game_over`. Điều kiện chuyển sang `:game_over` đổi từ "trúng bất kỳ đạn địch nào" thành "`player.hp` giảm xuống 0".

## `Player` — trường bổ sung

| Field | Description |
|-------|-------------|
| `hp` | Số nguyên, `0 <= hp <= max_hp`. Giảm 1 khi trúng đạn (không khiên, không bất tử). Game over khi về 0. |
| `max_hp` | Số nguyên dương cố định (`Health.max_hp/0`), không đổi trong một ván. |
| `invulnerable_until` | Số nguyên hoặc `nil`. Mốc `play_tick` tuyệt đối mà bất tử kết thúc. `nil` hoặc `<= play_tick` hiện tại nghĩa là không bất tử. |

`active_effects`, `shield`, `shield_expires_at` (từ 003) không đổi cấu trúc, chỉ tương tác thêm với `hp`/`invulnerable_until` theo luật ở mục dưới.

## Va chạm — mở rộng luật hiện có (thay thế luật một-hit-chết của 001/003)

Thứ tự xử lý mỗi tick trong `Simulation.step/1` (phần liên quan tới sinh mạng), sau khi `cull_offscreen/1`:

1. **`absorb_shield/1`** (không đổi từ 003): nếu `player.shield == true` và có đạn địch chạm, tiêu thụ chính viên đạn đó, tắt khiên, **không** chạm tới `hp`/`invulnerable_until`.
2. **`apply_damage/1`** (mới):
   - Nếu `player.invulnerable_until` còn hiệu lực (`invulnerable_until > play_tick`): không làm gì. Đạn địch tiếp tục tồn tại (không bị tiêu thụ), sẽ bị `cull_offscreen/1` dọn ở tick sau như thường lệ.
   - Ngược lại, nếu `Collision.enemy_hits_player?(enemy_bullets, player)` trả `true`: `hp = max(0, hp - 1)`, `invulnerable_until = play_tick + Health.invulnerability_duration_ticks()`.
   - Ngược lại (không đạn nào chạm): không đổi.
3. **`check_player_death/1`** (thay đổi điều kiện): `if player.hp <= 0, do: GameState.new_game_over(s), else: s`. Không còn gọi `Collision.enemy_hits_player?/2` trực tiếp ở bước này — điều kiện chết đã được quyết định hoàn toàn bởi `hp` do `apply_damage/1` cập nhật.

## Khởi tạo ván mới (`GameState.new_playing/0`)

- `player.hp: Health.max_hp()`, `player.max_hp: Health.max_hp()`, `player.invulnerable_until: nil`.
- Đảm bảo FR-010: không kế thừa máu/bất tử từ ván trước vì `new_playing/0` luôn tạo player mới hoàn toàn (giống nguyên tắc đã áp dụng cho `active_effects`/`shield` ở 003).

## Validation / biên

- `0 <= hp <= max_hp` tại mọi thời điểm sau một bước `Simulation.step/1`.
- `invulnerable_until` chỉ có ý nghĩa khi so với `play_tick` hiện tại; giá trị `nil` và giá trị `<= play_tick` tương đương về mặt hành vi (không bất tử) — `apply_damage/1` không phân biệt hai trường hợp này khi kiểm tra điều kiện.
- Khi `player.shield == true` tại thời điểm trúng đạn, `hp` và `invulnerable_until` **không đổi** trong cùng tick đó (FR-008) — `absorb_shield/1` phải tiêu thụ hết đạn chạm người chơi ở tick đó *trước khi* `apply_damage/1` chạy, nếu không cả hai cơ chế có thể cùng kích hoạt sai cho cùng một sự kiện trúng đạn (do đó thứ tự pipeline ở trên là bắt buộc, không thể hoán đổi).

## Snapshot JSON (`frame`) — trường bổ sung

| Field | Ghi chú |
|-------|---------|
| `player_invulnerable` | Boolean; rút gọn từ `invulnerable_until > play_tick`, **không** gửi mốc tick tuyệt đối ra client (cùng nguyên tắc đã áp dụng cho `player_effects` ở 003). |

`hp`/`max_hp` không cần thêm vào snapshot `frame` cho canvas — hiển thị qua `player: g.player` (đã gửi nguyên player map từ 003) hoặc trực tiếp qua LiveView assigns trong template HEEx (xem `research.md` §6), tuỳ cách `GameLive` chọn hiển thị.
