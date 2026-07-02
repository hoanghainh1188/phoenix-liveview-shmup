# Quickstart: Kiểm tra feature 004 (máu/mạng người chơi)

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

- `Health` — hằng số/bảng tham số (`max_hp`, `invulnerability_duration_ticks`).
- `Simulation` — trúng đạn trừ đúng 1 hp và kích hoạt bất tử; bất tử chặn trừ máu tiếp; hết bất tử trừ máu lại bình thường; nhiều đạn trúng cùng tick chỉ trừ 1 hp; khiên không trừ máu/không kích hoạt bất tử; game over đúng khi hp về 0 (không đúng khi hp > 0 dù trúng đạn).
- `GameState.new_playing/0` — hp/max_hp/invulnerable_until luôn về mặc định, không kế thừa ván trước (FR-010).

## Chạy tay

```bash
cd shmup
mix phx.server
```

Mở URL dev (mặc định `http://localhost:4000`), **BẮT ĐẦU**, cố ý để trúng đạn địch:

- Quan sát dòng "Máu: X/Y" giảm đúng 1 mỗi lần trúng (không kết thúc ván ngay).
- Ngay sau khi trúng, tàu **nhấp nháy** trong khoảng ~3 giây — lái vào luồng đạn khác trong lúc này để xác nhận không bị trừ thêm máu.
- Đợi hết nhấp nháy, trúng đạn tiếp theo trừ máu lại bình thường.
- Để máu về 0: xác nhận ván kết thúc (Hết trận) như luật cũ.
- Nếu đã nhặt khiên (feature 003) trước khi trúng đạn: xác nhận máu không đổi và tàu **không** nhấp nháy sau đó (khiên không kích hoạt bất tử).
- Bắt đầu ván mới sau game over: xác nhận máu về lại tối đa, không còn nhấp nháy sót lại.

## Gỡ lỗi nhanh

- Ván vẫn kết thúc ngay lần trúng đầu: kiểm tra `check_player_death/1` đã đổi sang so `player.hp <= 0` thay vì gọi `Collision.enemy_hits_player?/2` trực tiếp.
- Bất tử không chặn được trừ máu: kiểm tra `apply_damage/1` so `invulnerable_until` với `play_tick` **hiện tại của tick đó** (đã tăng ở `advance_play_time/1` đầu `step/1`), không phải giá trị play_tick cũ trước khi tăng.
- Khiên vẫn bị trừ máu: kiểm tra thứ tự pipeline — `absorb_shield/1` phải chạy **trước** `apply_damage/1`.
