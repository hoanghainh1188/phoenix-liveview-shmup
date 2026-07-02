# Quickstart: Kiểm tra feature 006 (hiệu ứng xác nhận trúng đạn)

## Chuẩn bị

```bash
cd shmup
mix deps.get
mix compile
```

## Kiểm thử tự động

```bash
cd shmup
mix test
```

Sau khi triển khai: thêm/chạy test tập trung vào `Shmup.Game.Simulation` —

- Hạ một địch → `kill_events` chứa đúng `%{x, y, kind}` của địch đó trong tick đó.
- Không có địch nào bị hạ trong tick → `kill_events == []`.
- Địch bị cull do ra khỏi màn hình (chưa từng hp về 0) → không xuất hiện trong `kill_events`.
- `GameState.new_playing/0` → `kill_events == []`.

Không có bộ test JS tự động trong dự án — phần hiển thị (nổ, nhấp nháy điểm) xác minh thủ công theo các bước dưới.

## Chạy tay

```bash
cd shmup
mix phx.server
```

Mở URL dev (mặc định `http://localhost:4000`), **BẮT ĐẦU**, và:

- Hạ một địch: quan sát hiệu ứng nổ/flash xuất hiện đúng tại vị trí địch, tự biến mất sau khoảng ~0.3–0.5 giây.
- Để một địch trôi hết xuống đáy màn hình mà không bắn trúng: xác nhận **không** có hiệu ứng nổ nào xuất hiện.
- Quan sát dòng "Điểm": xác nhận nhấp nháy/nổi bật ngắn ngay khi điểm tăng, không nhấp nháy khi điểm không đổi.
- Chơi tới khi hạ được boss (tier 5+, xem `specs/005-shmup-enemy-variety/quickstart.md`): xác nhận hiệu ứng nổ của boss rõ ràng lớn hơn/nổi bật hơn so với hạ grunt/tank.
- Game over rồi chơi lại: xác nhận không có hiệu ứng nổ nào từ ván trước hiển thị lại, và điểm đầu tiên kiếm được ở ván mới vẫn kích hoạt nhấp nháy bình thường (không bị "nuốt" do so sánh với điểm cuối ván trước).

## Gỡ lỗi nhanh

- Không thấy hiệu ứng nổ: kiểm tra `kill_events` có trong payload `frame` (xem `specs/006-shmup-hit-feedback/contracts/liveview-hook-events.md`) và `game_hook.js` có push vào `this.explosions` đúng cách.
- Điểm không nhấp nháy ở ván mới sau ván đầu: kiểm tra `this._lastScore`/`this.explosions` có được reset trong nhánh phát hiện chuyển vào `:playing` ở `updated()`.
- Hiệu ứng nổ "dính" mãi không biến mất: kiểm tra bước lọc theo tuổi (`EXPLOSION_LIFETIME_MS`) chạy đúng mỗi `draw()`, không chỉ chạy một lần khi thêm mới.
