# Phase 0 Research: Hiệu ứng xác nhận trúng đạn (006)

## 1. Nguồn dữ liệu sự kiện hạ địch — tái dùng `killed`, không đổi `Collision`

**Decision**: `Collision.resolve_player_bullets_vs_enemies/3` đã trả về danh sách `killed` (các enemy map bị hạ trong tick đó) từ khi feature 003 cần nó để sinh power-up. `Simulation.resolve_hits/1` chỉ cần thêm một dòng: `kill_events: Enum.map(killed, &Map.take(&1, [:x, :y, :kind]))` vào state trả về — **không đổi chữ ký hoặc hành vi `Collision`**.

**Rationale**: Zero rủi ro hồi quy cho API đã ổn định qua 4 feature; tái dùng đúng dữ liệu đã tính sẵn thay vì tính lại.

---

## 2. `kill_events` tự động rỗng mỗi tick — không cần bước reset riêng

**Decision**: Vì `resolve_hits/1` chạy **đúng một lần mỗi tick, luôn gán lại** `kill_events` (kể cả bằng `[]` khi `killed == []`), trường này tự nhiên chỉ tồn tại đúng trong tick nó xảy ra — không cần thêm stage "clear kill_events" riêng trong pipeline.

**Rationale**: Đơn giản hơn thêm một bước reset tường minh; đúng nguyên tắc "state nhất thời chỉ sống 1 tick" mà không cần cơ chế mới.

**Alternatives considered**:

- Tích lũy `kill_events` qua nhiều tick rồi để client tự lọc theo timestamp — không cần thiết, phức tạp hóa không có lợi ích, và có nguy cơ rò rỉ sự kiện cũ nếu client bỏ lỡ một frame.

---

## 3. Client-side explosion state — không đưa vào `%GameState{}`

**Decision**: `game_hook.js` giữ một mảng `this.explosions` (list `{x, y, kind, bornAt}`, `bornAt` = `performance.now()` tại thời điểm nhận `kill_events`). Mỗi lần `draw(p)` chạy: (a) với mỗi phần tử trong `p.kill_events`, push một explosion mới vào `this.explosions`; (b) lọc bỏ mọi explosion có tuổi > `EXPLOSION_LIFETIME_MS` (350ms); (c) vẽ các explosion còn lại với bán kính/alpha giảm dần theo tuổi.

**Rationale**: Hiệu ứng hoàn toàn trình bày, không có ý nghĩa gameplay — dùng đồng hồ thực (`performance.now()`) của client thay vì tick server là hợp lý và đơn giản nhất, khác với hiệu ứng nhấp nháy bất tử (004) vốn phải đồng bộ với trạng thái *thực* trên server (`invulnerable_until`). Giữ ngoài `%GameState{}` vì đây không phải dữ liệu server cần biết hay test.

**Alternatives considered**:

- Đồng bộ thời lượng hiệu ứng theo `play_tick` (giống bất tử) — không cần thiết vì explosion không phản ánh trạng thái server đang bật/tắt, chỉ là một sự kiện một lần.

---

## 4. Cường độ hiệu ứng theo `kind` (US3)

**Decision**: Bán kính tối đa của hiệu ứng nổ tra theo `kind`: `grunt: 18`, `tank: 26`, `boss: 45` (đơn vị canvas, cùng hệ tọa độ 480×640). Màu theo đúng bảng màu địch đã có (`enemyColors` trong `game_hook.js` từ feature 005) để nhất quán — nổ màu tím nhạt cho grunt, cam cho tank, đỏ cho boss.

**Rationale**: Tái dùng bảng màu theo kind đã có sẵn (005) thay vì định nghĩa bảng màu riêng cho hiệu ứng nổ — nhất quán trực quan (người chơi đã quen "đỏ = boss").

---

## 5. Nhấp nháy điểm số — CSS animation qua DOM, không qua canvas

**Decision**: Thêm `id="score-value"` vào `<span>` hiển thị điểm trong `game_live.ex`. `game_hook.js` theo dõi `this._lastScore`; mỗi `draw(p)`, nếu `p.score > this._lastScore`, lấy phần tử qua `this.el.querySelector("#score-value")`, xóa rồi thêm lại class `score-pulse` (kèm reflow ép buộc để animation chạy lại nếu bị kích hoạt liên tiếp nhanh), cập nhật `this._lastScore = p.score`. `app.css` định nghĩa `@keyframes score-pulse` (phóng to nhẹ + đổi màu ngắn) — **không dùng `@apply`** theo đúng quy tắc CSS hiện có của repo.

**Rationale**: "Điểm" vốn đã hiển thị qua LiveView DOM (template), không qua canvas (xem `CLAUDE.md`) — nhấp nháy nên là CSS animation trên chính DOM đó thay vì chuyển toàn bộ việc hiển thị điểm sang canvas, giữ nguyên kiến trúc hiện có (LiveView diffing cho số liệu, canvas chỉ cho playfield).

**Alternatives considered**:

- Vẽ điểm số trên canvas thay vì DOM — thay đổi kiến trúc hiển thị hiện có không cần thiết chỉ để có hiệu ứng nhấp nháy; CSS animation trên DOM đạt cùng mục tiêu với thay đổi tối thiểu.

---

## 6. `this._lastScore`/`this.explosions` phải reset khi vào ván mới

**Decision**: Trong `updated()` (đã có logic phát hiện chuyển **vào** `:splash` từ phase khác), thêm nhánh tương tự phát hiện chuyển **vào** `:playing` (`phase === "playing" && this._prevPhase !== "playing"`): reset `this._lastScore = 0` và `this.explosions = []`.

**Rationale**: Nếu không reset, điểm 0 đầu ván mới sẽ so với `_lastScore` là điểm cuối ván trước (một số dương) → điểm đầu tiên kiếm được ở ván mới sẽ **không** kích hoạt nhấp nháy (vì `10 > 50` sai) — đúng bug edge case đã nêu trong spec ("không được sót hiệu ứng/trạng thái từ ván trước", áp dụng tương tự cho việc *thiếu* hiệu ứng do state cũ sót lại).
