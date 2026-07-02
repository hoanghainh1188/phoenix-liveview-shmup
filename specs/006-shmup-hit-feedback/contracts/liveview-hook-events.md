# Contract: LiveView ↔ JS Hook (Game) — mở rộng 006

Cơ sở: [001](../../001-shmup-start-gameplay/contracts/liveview-hook-events.md)–[005](../../005-shmup-enemy-variety/contracts/liveview-hook-events.md). Mọi sự kiện và tên ổn định ở đó vẫn áp dụng; bên dưới chỉ **phần bổ sung / thay đổi tải**.

## Client → Server (`pushEvent`)

Không đổi cho 006: `input` vẫn là luồng chính. Không thêm sự kiện mới — hiệu ứng hoàn toàn một chiều (server → client), không có phản hồi ngược từ hiệu ứng hình ảnh.

## Server → Client (`push_event`)

### `frame` (khi `playing`)

Payload hiện có **thêm** một trường:

| Field | Type | Khi nào | Ghi chú |
|-------|------|---------|---------|
| `kill_events` | list | Mỗi tick `:playing` | `%{x, y, kind}` cho mỗi địch bị hạ trong đúng tick đó; **rỗng ở hầu hết các tick**. `kind` là string sau khi Jason encode. |

### `phase`

Không đổi.

## Hiệu ứng client-only (không phải sự kiện `pushEvent`/`push_event`)

Hai hiệu ứng hình ảnh trong feature này **không** đi qua cơ chế sự kiện Phoenix — chúng là logic thuần JS/CSS phản ứng với dữ liệu đã có trong `frame`:

- **Nổ khi hạ địch**: client tự quản lý danh sách explosion cục bộ từ `kill_events`, không cần sự kiện riêng.
- **Nhấp nháy điểm**: client tự so sánh `frame.score` giữa hai lần `draw()` liên tiếp, không cần server gửi tín hiệu "điểm vừa tăng" riêng.

## Tương thích ngược

- Hook cũ (chưa đọc `kill_events`): bỏ qua field không biết, hành vi y hệt 005 (không có hiệu ứng nổ, nhưng không lỗi).
- Thay đổi breaking: không có — `kill_events` là field bổ sung, luôn có mặt (có thể rỗng) trong payload `:playing`.

## Ordering & performance

- Tần suất `frame` không đổi (~20 Hz).
- `kill_events` giới hạn tự nhiên bởi số địch tối đa có thể bị hạ trong một tick (bị chặn bởi `max_enemies`/số đạn tối đa trên màn hình hiện có) — không cần giới hạn riêng.
