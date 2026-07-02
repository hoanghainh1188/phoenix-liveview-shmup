# Contract: LiveView ↔ JS Hook (Game) — mở rộng 004

Cơ sở: [001 contracts](../../001-shmup-start-gameplay/contracts/liveview-hook-events.md), [002 contracts](../../002-shmup-difficulty-waves/contracts/liveview-hook-events.md), [003 contracts](../../003-shmup-powerups/contracts/liveview-hook-events.md). Mọi sự kiện và tên ổn định ở đó vẫn áp dụng; bên dưới chỉ **phần bổ sung / thay đổi tải**.

## Client → Server (`pushEvent`)

Không đổi bắt buộc cho 004: `input` vẫn là luồng chính. Không thêm sự kiện bắt buộc mới — máu/bất tử hoàn toàn do server tính và đẩy xuống qua `frame`.

## Server → Client (`push_event`)

### `frame` (khi `playing`)

Payload hiện có (`tick`, `score`, `width`, `height`, `difficulty_tier`, `play_tick`, `player`, `player_bullets`, `enemy_bullets`, `enemies`, `powerups`, `player_effects`) **có thể** mở rộng thêm:

| Field | Type | Khi nào | Ghi chú |
|-------|------|---------|---------|
| `player_invulnerable` | boolean | Mỗi tick `:playing` | Cờ hiện diện, rút gọn từ `invulnerable_until > play_tick`; **không** gửi mốc tick tuyệt đối. |

`player` (đã gửi nguyên map từ 003) giờ có thêm `hp`, `max_hp`, `invulnerable_until` — tất cả đều là số nguyên/`nil`, JSON-safe, không cần lọc thêm khóa.

### `phase`

Không đổi: `splash` | `playing` | `game_over`. Điều kiện server chuyển sang `game_over` đổi (dựa trên `hp <= 0` thay vì trúng đạn bất kỳ) nhưng **hình dạng payload của sự kiện** (`%{phase: "game_over", score: ...}`) không đổi.

## Hiển thị máu (ngoài `frame`)

Số "Máu: X/Y" hiển thị qua **LiveView assigns/template** (không qua JS hook/canvas) — đọc trực tiếp `@game.player.hp`/`@game.player.max_hp` trong HEEx, tương tự cách "Điểm" hiện có được hiển thị. Không cần thêm sự kiện `push_event` riêng cho việc này.

## Tương thích ngược

- Hook cũ (chưa đọc `player_invulnerable`): tiếp tục vẽ player đặc như 003, bỏ qua cờ không biết — không nhấp nháy nhưng không lỗi.
- Thay đổi breaking: không có — mọi field mới đều tuỳ chọn (client bỏ qua an toàn nếu chưa xử lý).

## Ordering & performance

- Tần suất `frame` không đổi (~20 Hz).
- Payload tăng thêm không đáng kể (vài trường số nguyên/boolean trên `player` đã gửi sẵn, cộng một boolean top-level).
