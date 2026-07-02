# Contract: LiveView ↔ JS Hook (Game) — mở rộng 003

Cơ sở: [001 contracts](../../001-shmup-start-gameplay/contracts/liveview-hook-events.md), [002 contracts](../../002-shmup-difficulty-waves/contracts/liveview-hook-events.md). Mọi sự kiện và tên ổn định ở đó vẫn áp dụng; bên dưới chỉ **phần bổ sung / thay đổi tải**.

## Client → Server (`pushEvent`)

Không đổi bắt buộc cho 003: `input` vẫn là luồng chính (di chuyển + fire). Không thêm sự kiện bắt buộc mới — nhặt powerup là kết quả va chạm phía server, không phải hành động rời rạc từ client.

## Server → Client (`push_event`)

### `frame` (khi `playing`)

Payload hiện có (`tick`, `score`, `width`, `height`, `difficulty_tier`, `play_tick`, `player`, `player_bullets`, `enemy_bullets`, `enemies`) **có thể** mở rộng thêm:

| Field | Type | Khi nào | Ghi chú |
|-------|------|---------|---------|
| `powerups` | list | Mỗi tick `:playing` | Vật phẩm đang rơi: `%{id, x, y, w, h, kind}`. `kind` là string (`"rapid_fire"` \| `"multi_shot"` \| `"shield"`) sau khi Jason encode atom. |
| `player_effects` | map | Mỗi tick `:playing` | `%{rapid_fire: boolean, multi_shot: boolean, shield: boolean}` — cờ hiện diện, **không** gửi tick hết hạn tuyệt đối. |

**Projection `powerups` (JSON)**: Chỉ gửi các khóa hình học + `kind` cần để vẽ; không gửi field nội bộ nào khác nếu sau này `Powerup` struct có thêm field debug. Theo đúng nguyên tắc JSON-safe đã áp dụng cho `enemies` ở 001/002 (xem `CLAUDE.md`) — nếu một field mới không phải kiểu JSON cơ bản (số, string, bool, list, map), nó **không** được đưa thẳng vào payload.

### `phase`

Không đổi: `splash` | `playing` | `game_over`.

## Tương thích ngược

- Hook cũ (chưa đọc `powerups`/`player_effects`): tiếp tục vẽ đúng như 002, bỏ qua field không biết.
- Thay đổi breaking: nếu cấu trúc `powerups` hoặc `player_effects` đổi sau này, cập nhật đồng thời `game_hook.js` + test snapshot.

## Ordering & performance

- Tần suất `frame` không đổi (~20 Hz).
- `powerups` bị giới hạn bởi `max_falling_powerups` (xem `research.md` §6) nên payload tăng thêm không đáng kể.
