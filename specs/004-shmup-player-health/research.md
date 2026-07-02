# Phase 0 Research: Máu/mạng người chơi (004)

## 1. Số máu tối đa và biểu diễn dữ liệu

**Decision**: `max_hp = 3` (hằng số trong module `Health`), `hp` khởi tạo bằng `max_hp` trong `new_playing/0`. Biểu diễn đơn giản bằng số nguyên trên player map (`hp: 3, max_hp: 3`), không cần cấu trúc phức tạp hơn (không có "loại máu" khác nhau).

**Rationale**: 3 mạng là chuẩn phổ biến cho thể loại shmup MVP, đủ để tạo cảm giác "có cơ hội thứ hai" mà không làm mất độ khó đã xây ở 002. Số nguyên đơn giản dễ test và dễ hiển thị.

**Alternatives considered**:

- Thanh máu phần trăm (float 0.0–1.0) — không cần thiết khi mỗi lần trúng luôn trừ đúng 1 điểm cố định; số nguyên nhỏ dễ hiển thị dạng "2/3" hơn.

---

## 2. Thời lượng bất tử

**Decision**: `invulnerability_duration_ticks = 60` (~3 giây ở 20 Hz), lưu dưới dạng mốc tuyệt đối `invulnerable_until` (mốc `play_tick`), theo đúng mẫu `expires_at_tick` đã dùng cho hiệu lực power-up ở 003 (`research.md` §2 của 003). Mỗi tick, `Simulation.step/1` so `invulnerable_until <= play_tick` để tự động tắt bất tử — không cần trường boolean riêng, `invulnerable_until == nil` (hoặc `0`) nghĩa là không bất tử.

**Rationale**: Nhất quán với mẫu mốc tuyệt đối đã dùng cho `active_effects`/`shield_expires_at` ở 003 — dễ test tất định (`assert bất tử tại tick N`, `assert hết bất tử tại tick N+60`), và không cần thêm cờ boolean đồng bộ thủ công (khác với `shield` vốn cần cờ riêng vì bản thân việc "có khiên" ảnh hưởng tới việc có tiêu hao ngay không).

**Alternatives considered**:

- Đếm ngược giảm dần mỗi tick (thay vì mốc tuyệt đối) — tương đương hành vi nhưng mốc tuyệt đối đơn giản hơn khi kết hợp với logic "kích hoạt bất tử = gán lại `invulnerable_until`".

---

## 3. Thứ tự trừ máu trong pipeline — quan hệ với khiên (003)

**Decision**: Giữ nguyên bước `absorb_shield/1` đã có (003) chạy **trước**. Thêm một bước mới `apply_damage/1` chạy **ngay sau** `absorb_shield/1` và **trước** bước kết thúc game cũ (`check_player_death/1`, được thay bằng kiểm tra `hp <= 0`):

```text
... |> cull_offscreen() |> absorb_shield() |> apply_damage() |> check_player_death()
```

`apply_damage/1`:
1. Nếu `player.invulnerable_until` còn hiệu lực (`> play_tick`) → không làm gì (giữ nguyên `enemy_bullets`, không trừ máu). *(Lựa chọn thiết kế: đạn xuyên qua người chơi trong lúc bất tử — không tiêu thụ đạn, đúng cảm giác "vô hình" thay vì "khiên chặn đạn".)*
2. Nếu không bất tử và có đạn địch chạm người chơi (`Collision.enemy_hits_player?/2`) → trừ 1 `hp`, đặt `invulnerable_until = play_tick + Health.invulnerability_duration_ticks()`. Không cần tiêu thụ/loại bỏ viên đạn cụ thể (khác khiên) — mọi đạn đang chạm ở tick đó chỉ tính là **một** sự kiện trúng, và các viên đạn tiếp tục di chuyển bình thường (sẽ bị dọn dẹp khi ra khỏi màn hình như thường lệ) chứ không biến mất ngay, giữ đơn giản và nhất quán với cách `enemy_hits_player?/2` cũ chỉ **kiểm tra** mà không sửa `enemy_bullets`.
3. `check_player_death/1` chỉ còn kiểm tra `player.hp <= 0` (thay cho `Collision.enemy_hits_player?/2` như bản cũ trước 004).

**Rationale**: Đặt sau `absorb_shield/1` đảm bảo khiên vẫn "chặn hoàn toàn" trước khi luật máu được xét — nếu khiên đã tiêu thụ viên đạn duy nhất đang chạm người chơi ở tick đó, `apply_damage/1` sẽ không thấy đạn nào chạm nữa (đúng FR-008: không trừ máu, không kích hoạt bất tử). Việc không tiêu thụ đạn khi trừ máu (khác khiên) giữ hành vi đơn giản và không cần thay đổi `Collision.enemy_hits_player?/2`.

**Alternatives considered**:

- Tiêu thụ (loại bỏ) mọi đạn chạm người chơi khi trừ máu, giống khiên — cân nhắc nhưng không bắt buộc theo spec; để đạn tiếp tục bay giữ hành vi tối giản và tránh thay đổi ngữ nghĩa hiện có của `enemy_hits_player?/2`.

---

## 4. Nhiều đạn trúng cùng tick chỉ trừ 1 máu (FR-009)

**Decision**: `apply_damage/1` dùng `Collision.enemy_hits_player?/2` (trả về boolean — đã có sẵn, không đổi) thay vì đếm số đạn trúng. Vì hàm này vốn chỉ trả `true`/`false`, việc trừ đúng 1 `hp` mỗi tick là hệ quả tự nhiên của việc gọi nó đúng một lần trong `apply_damage/1`, không cần logic đếm riêng.

**Rationale**: Tái sử dụng hàm đã có, không cần thêm API mới trong `Collision` cho phần này — đơn giản hoá đúng theo YAGNI.

---

## 5. Tín hiệu hình ảnh khi bất tử (FR-007)

**Decision**: Snapshot `frame` thêm `player_invulnerable: boolean` (rút gọn từ so sánh `invulnerable_until > play_tick` phía server, không gửi mốc tick tuyệt đối ra client — cùng nguyên tắc đã áp dụng cho `player_effects` ở 003). `game_hook.js` khi vẽ player: nếu `player_invulnerable`, dao động `globalAlpha` theo `tick % N` (nhấp nháy) thay vì vẽ đặc như bình thường.

**Rationale**: Nhất quán với cách 003 xử lý `player_effects` — chỉ gửi cờ boolean, không rò rỉ chi tiết tick nội bộ; hiệu ứng nhấp nháy dùng compositor-friendly property (`globalAlpha`) trên canvas, không cần asset/animation phức tạp.

---

## 6. Hiển thị máu trên UI (FR-006)

**Decision**: Thêm dòng "Máu: X/Y" trong template HEEx của `GameLive` (cạnh dòng "Điểm" đã có khi `@game.phase == :playing`), đọc trực tiếp từ `@game.player.hp`/`@game.player.max_hp` — không cần qua canvas/JS hook vì đây là dữ liệu LiveView đã có trong assigns, giống cách "Điểm" hiện tại được hiển thị.

**Rationale**: Đơn giản nhất có thể, dùng LiveView diffing thay vì vẽ thêm trên canvas; khớp mức độ UI tối thiểu đã áp dụng cho `difficulty_tier`/`player_effects` (chỉ hiển thị text debug trên canvas cho các chỉ số phụ, còn máu — chỉ số sống còn quan trọng nhất — xứng đáng nằm trong DOM chính như điểm số).

---

## 7. Bảng tham số (`Health` module, giống vai trò `Difficulty`/`Powerups`)

| Tham số | Giá trị MVP | Ghi chú |
|---|---|---|
| `max_hp` | 3 | Máu tối đa/khởi điểm |
| `invulnerability_duration_ticks` | 60 (~3s @ 20Hz) | Thời lượng bất tử sau khi mất máu |

**Rationale**: Tách bảng tham số khỏi `Simulation`, đúng tiền lệ `Difficulty` (002) và `Powerups` (003) — dễ tinh chỉnh cân bằng mà không sửa pipeline.
