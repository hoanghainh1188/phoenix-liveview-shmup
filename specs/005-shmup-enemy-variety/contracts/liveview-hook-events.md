# Contract: LiveView ↔ JS Hook (Game) — mở rộng 005

Cơ sở: [001](../../001-shmup-start-gameplay/contracts/liveview-hook-events.md), [002](../../002-shmup-difficulty-waves/contracts/liveview-hook-events.md), [003](../../003-shmup-powerups/contracts/liveview-hook-events.md), [004](../../004-shmup-player-health/contracts/liveview-hook-events.md). Mọi sự kiện và tên ổn định ở đó vẫn áp dụng; bên dưới chỉ **phần bổ sung / thay đổi tải**.

## Client → Server (`pushEvent`)

Không đổi bắt buộc cho 005: `input` vẫn là luồng chính. Không thêm sự kiện mới — đa dạng địch/boss hoàn toàn do server quyết định và đẩy xuống qua `frame`.

## Server → Client (`push_event`)

### `frame` (khi `playing`)

Phần tử trong mảng `enemies` (đã lọc qua `@enemy_snapshot_keys`) **thêm** một khóa:

| Field | Type | Khi nào | Ghi chú |
|-------|------|---------|---------|
| `kind` | string | Mỗi enemy, mỗi tick `:playing` | `"grunt"` \| `"tank"` \| `"boss"` — atom phía server, Jason tự encode thành string. |

Không có field top-level mới ở cấp `frame` (khác 003/004 vốn thêm `powerups`/`player_effects`/`player_invulnerable`) — mọi thông tin đa dạng địch/boss nằm trong chính từng phần tử `enemies`.

### `phase`

Không đổi.

## Tương thích ngược

- Hook cũ (chưa đọc `enemy.kind`): tiếp tục vẽ mọi enemy cùng một màu như 001–004, dùng đúng `w`/`h` đã khác nhau theo kind — vẫn phân biệt được phần nào qua kích thước dù không đúng màu.
- Thay đổi breaking: không có — `kind` là field bổ sung, không thay hình dạng các field hiện có.

## Ordering & performance

- Tần suất `frame` không đổi (~20 Hz).
- Payload tăng thêm không đáng kể (một string ngắn mỗi enemy, số lượng enemy vẫn giới hạn bởi `max_enemies(tier)` + tối đa 1 boss vượt trần tại đúng tick sinh).
