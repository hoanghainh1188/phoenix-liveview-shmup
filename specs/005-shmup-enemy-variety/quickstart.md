# Quickstart: Kiểm tra feature 005 (đa dạng địch và boss)

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

- `Enemies` — hằng số/bảng tham số (tank multipliers, boss interval/multiplier/bonus, kích thước boss).
- `Simulation` — `pick_kind/2` tất định theo tier/id; tank có hp cao hơn/tốc độ chậm hơn grunt cùng tier; boss sinh đúng một lần khi vượt mốc `next_boss_tier`, không sinh lại cho tới mốc kế tiếp; boss hp vượt trội; hạ boss cộng điểm thưởng lớn hơn nhiều lần so với hạ grunt/tank; boss vượt được `max_enemies` tại đúng tick sinh.
- `GameState.new_playing/0` — `next_boss_tier` reset về mốc đầu tiên, không kế thừa ván trước.

## Chạy tay

```bash
cd shmup
mix phx.server
```

Mở URL dev (mặc định `http://localhost:4000`), **BẮT ĐẦU**, chơi đủ lâu để vượt tier 2 rồi tier 5:

- Từ tier 2 trở đi: quan sát thấy địch màu cam, to hơn xen kẽ địch tím thường — đây là `:tank`, cần nhiều phát bắn hơn để hạ.
- Khi vượt tier 5 (~50 giây chơi liên tục): một địch đỏ, rất to xuất hiện chính giữa màn hình — đây là boss.
- Hạ được boss: quan sát điểm tăng vọt (nhiều hơn hẳn so với hạ grunt/tank ngay trước đó).
- Tiếp tục chơi qua tier 10: xác nhận có boss thứ hai xuất hiện (không phải 0, không phải nhiều boss dồn dập).
- Game over rồi chơi lại: xác nhận vẫn thấy boss xuất hiện lại đúng từ tier 5 của ván mới (không bị "dùng hết").

## Gỡ lỗi nhanh

- Không thấy tank: kiểm tra `tank_min_tier`/`tank_chance_pct` trong `Enemies` và việc `pick_kind/2` được gọi đúng trong `spawn_one_enemy/1`.
- Không thấy boss: kiểm tra `maybe_spawn_boss/1` có chạy sau `advance_play_time/1` trong `step/1`, và điều kiện dùng `>=` (không phải `==`) để không bỏ sót mốc.
- Điểm thưởng boss không rõ rệt: kiểm tra bonus được cộng **sau** điểm cơ bản, dựa trên danh sách `killed` trả về từ `Collision.resolve_player_bullets_vs_enemies/3` (không đổi API hàm này).
