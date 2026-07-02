# Quickstart: Kiểm tra feature 003 (power-up và vũ khí nâng cấp)

## Chuẩn bị

```bash
cd shmup
mix deps.get
mix compile
```

Cần Erlang/Elixir (Mise: xem `.mise.toml` ở root repo).

## Kiểm thử tự động

```bash
cd shmup
mix test
```

Sau khi triển khai: thêm/chạy test tập trung vào `Shmup.Game` —

- `Powerups` — hằng số/bảng tham số (drop chance, thời hạn, cooldown, số tia).
- `Simulation` — rơi powerup tất định khi hạ địch (id cụ thể ⇒ rơi/không rơi loại nào), gia hạn khi nhặt trùng loại, hết hạn đúng tick, kết hợp `rapid_fire` + `multi_shot`.
- `Collision` — nhặt powerup (AABB), khiên hấp thụ đúng một lần trúng rồi tiêu hao, không có khiên thì game over như cũ.
- `GameState.new_playing/0` — không kế thừa hiệu lực từ ván trước (FR-009).

## Chạy tay

```bash
cd shmup
mix phx.server
```

Mở URL dev (mặc định `http://localhost:4000`), **BẮT ĐẦU**, chơi và hạ nhiều địch:

- Thỉnh thoảng thấy **vật phẩm rơi** từ vị trí địch vừa hạ; lái tàu chạm vào để nhặt.
- Nhặt vật phẩm bắn nhanh: quan sát đạn bắn ra dày hơn rõ rệt; đợi ~15 giây thấy quay lại tốc độ cơ bản.
- Nhặt vật phẩm nhiều tia: quan sát mỗi lần bắn ra 3 viên đạn tỏa thay vì 1.
- Nhặt vật phẩm khiên, cố ý để trúng một viên đạn địch: ván **không** kết thúc; trúng đạn tiếp theo (không còn khiên) thì game over như cũ.
- Bắt đầu ván mới sau game over: xác nhận không còn hiệu lực/khiên nào sót lại từ ván trước.

## Gỡ lỗi nhanh

- Không thấy powerup rơi: kiểm tra `drop_chance_pct` trong `Powerups` và điều kiện `length(powerups) < max_falling_powerups`.
- Hiệu lực không tắt: kiểm tra bước hết hạn chạy **mỗi tick** trong `Simulation.step/1`, so `expires_at_tick` với `play_tick` hiện tại (không phải `tick` toàn session).
- Khiên hấp thụ nhưng ván vẫn kết thúc: kiểm tra thứ tự pipeline — bước hấp thụ khiên phải chạy **trước** `check_player_death/1`.
