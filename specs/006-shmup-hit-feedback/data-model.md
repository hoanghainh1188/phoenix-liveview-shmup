# Data Model: Hiệu ứng xác nhận trúng đạn (006)

Mở rộng mô hình logical trong [001](../001-shmup-start-gameplay/data-model.md)–[005](../005-shmup-enemy-variety/data-model.md). Trạng thái vẫn **authoritative** trên server cho phần luật chơi; hiệu ứng hình ảnh là **projection một chiều**, không có state tương ứng phía server ngoài sự kiện nhất thời dưới đây.

## State machine

Không đổi: `:splash` | `:playing` | `:game_over`.

## `GameState` — trường bổ sung

| Field | Type / notes |
|-------|----------------|
| `kill_events` | `[%{x: float, y: float, kind: atom}]`. Danh sách địch bị hạ **trong tick hiện tại**, luôn được gán lại (không tích lũy) mỗi lần `resolve_hits/1` chạy — rỗng ở mọi tick không có ai bị hạ. Không phải trạng thái lâu dài của ván chơi. |

## Sinh `kill_events` (mở rộng `resolve_hits/1`, không đổi `Collision`)

- `Collision.resolve_player_bullets_vs_enemies/3` đã trả về `killed` (enemy maps bị hạ trong tick). `resolve_hits/1` MUST gán `kill_events: Enum.map(killed, &Map.take(&1, [:x, :y, :kind]))`.
- Địch bị loại bỏ do `cull_offscreen/1` (ra khỏi màn hình mà chưa hp về 0) **không** xuất hiện trong `killed` (và do đó không có trong `kill_events`) — đúng FR-002, vì `cull_offscreen/1` chạy **sau** `resolve_hits/1` trong pipeline và không tương tác với `killed`/`kill_events` theo bất kỳ cách nào.

## Khởi tạo ván mới (`GameState.new_playing/0`)

- `kill_events: []`.
- Đảm bảo FR-008: không kế thừa sự kiện từ ván trước (dù bản chất `kill_events` vốn đã tự rỗng mỗi tick, vẫn cần giá trị khởi tạo hợp lệ khi ván bắt đầu ở tick 0 trước khi `resolve_hits/1` chạy lần đầu).

## Snapshot JSON (`frame`) — trường bổ sung

| Field | Ghi chú |
|-------|---------|
| `kill_events` | Danh sách `%{x, y, kind}`; `kind` atom encode thành string qua Jason (không phải tuple) — an toàn theo nguyên tắc JSON-safe hiện có. Rỗng ở hầu hết các tick. |

## Client-side ephemeral state (`game_hook.js`, ngoài `%GameState{}`)

| Field | Type / notes |
|-------|----------------|
| `this.explosions` | `[{x, y, kind, bornAt}]`. `bornAt` = `performance.now()` tại thời điểm nhận sự kiện. Phần tử tự bị lọc bỏ khi tuổi vượt `EXPLOSION_LIFETIME_MS` mỗi lần `draw()` chạy. Reset về `[]` khi vào ván mới (chuyển sang `:playing` từ phase khác). |
| `this._lastScore` | Số nguyên, điểm số ở lần `draw()` gần nhất — dùng để phát hiện điểm vừa tăng (kích hoạt nhấp nháy). Reset về `0` khi vào ván mới. |

## Validation / biên

- `kill_events` không bao giờ chứa entry cho địch bị cull offscreen (chỉ chứa entry khi thực sự hp về 0 do trúng đạn).
- `this.explosions`/`this._lastScore` không bao giờ ảnh hưởng ngược lại tới bất kỳ `pushEvent` nào gửi lên server — thuần túy đọc từ `frame` payload, không ghi.
