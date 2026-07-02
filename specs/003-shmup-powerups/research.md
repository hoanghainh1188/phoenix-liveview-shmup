# Phase 0 Research: Power-up và vũ khí nâng cấp (003)

## 1. Xác suất rơi vật phẩm — tất định để test được

**Decision**: Dùng cùng kỹ thuật tất định đã có ở `Simulation.spawn_one_enemy/1` (băm từ `tick`/`id` thay vì `:rand` không seed). Khi một địch bị hạ trong `resolve_hits/1`, tính `roll = rem(enemy.id * 2654435761, 100)` (hoặc tương đương) và so với ngưỡng `drop_chance_pct` (ví dụ **12%**) từ `Powerups`. Nếu `roll < drop_chance_pct`, sinh powerup tại vị trí địch vừa hạ; loại powerup chọn bằng `rem(enemy.id, 3)` ánh xạ tới `[:rapid_fire, :multi_shot, :shield]`.

**Rationale**: Giữ toàn bộ simulation là hàm thuần túy của state (không side-effect `:rand`), khớp nguyên tắc II của constitution và cho phép test viết kịch bản "địch id X luôn rơi loại Y" một cách xác định.

**Alternatives considered**:

- `:rand.uniform/1` mỗi lần hạ địch — không tất định, khó viết test chính xác tỉ lệ; chấp nhận được cho production nhưng vi phạm yêu cầu "testable" của spec (Assumptions/FR-001).
- Rơi 100% mỗi lần hạ địch — làm mất ý nghĩa "phần thưởng" (edge case trong spec: tỉ lệ quá cao).

---

## 2. Thời hạn hiệu lực và đơn vị thời gian

**Decision**: Thời hạn tính bằng **play_tick còn lại** (giống mô hình `play_tick`/tier ở 002), lưu trong player dưới dạng map `active_effects: %{rapid_fire: expires_at_tick, multi_shot: expires_at_tick}` (key vắng mặt = không hoạt động) và `shield: boolean`, `shield_expires_at: tick | nil`. Mỗi tick trong `Simulation.step/1`, hiệu lực nào có `expires_at_tick <= play_tick` bị xóa khỏi map. Thời hạn mặc định: **300 play_tick** (~15 giây ở 20 Hz) cho `rapid_fire`/`multi_shot`, **400 play_tick** (~20 giây) cho `shield` nếu không bị dùng tới.

**Rationale**: Nhất quán với cách 002 đã dùng `play_tick` cho chu kỳ tier — không cần đồng hồ tường, dễ test tất định (`assert active tại tick N`, `assert hết hạn tại tick N+300`).

**Alternatives considered**:

- Đếm ngược bằng số nguyên giảm dần mỗi tick (thay vì mốc tuyệt đối `expires_at_tick`) — tương đương về hành vi nhưng mốc tuyệt đối giúp "gia hạn" (FR-006) chỉ là một phép gán lại `play_tick + duration`, đơn giản hơn cộng dồn.

---

## 3. Gia hạn khi nhặt trùng loại (FR-006)

**Decision**: Nhặt powerup loại `k` luôn **đặt lại** `active_effects[k] = play_tick + duration(k)`, bất kể trước đó có đang hoạt động hay đã hết hạn. Không cộng dồn nhiều tầng — chỉ một mốc hết hạn cho mỗi loại tại một thời điểm.

**Rationale**: Đáp ứng đúng FR-006 và edge case "nhặt trùng loại đang hoạt động"; đơn giản hơn nhiều so với hàng đợi hiệu lực.

---

## 4. Kết hợp `:rapid_fire` + `:multi_shot` (FR-007)

**Decision**: `fire_player_bullet/1` kiểm tra độc lập hai điều kiện trên `active_effects`:

- Cooldown bắn: `if Map.has_key?(active_effects, :rapid_fire), do: rapid_cooldown, else: base_cooldown` (ví dụ giảm từ 10 tick xuống 5 tick).
- Số viên đạn mỗi lần bắn: `if Map.has_key?(active_effects, :multi_shot), do: 3, else: 1`, với 3 viên tỏa theo góc cố định (ví dụ `vx ∈ {-2.5, 0, 2.5}`, `vy = -14.0` không đổi) quanh vị trí mũi tàu.

Hai điều kiện độc lập nên tự nhiên **kết hợp** khi cả hai `active_effects` cùng có mặt — không cần logic loại trừ.

**Rationale**: Tách bạch "tốc độ" và "số tia" thành hai trục độc lập giúp code đơn giản và tự động thỏa FR-007 mà không cần case đặc biệt.

**Alternatives considered**:

- Multi-shot đạn tỏa theo góc (radial spread bằng lượng giác) thay vì offset `vx` cố định — trực quan hơn về "shmup cổ điển" nhưng phức tạp hơn cần thiết cho MVP; để lại như cải tiến sau nếu cần.

---

## 5. Khiên — hấp thụ một lần và tương tác với `check_player_death`

**Decision**: Trong `Collision`, thêm `absorb_or_hit?/2` (hoặc mở rộng `enemy_hits_player?/2`) để khi phát hiện enemy bullet chạm player: nếu `player.shield == true`, **tiêu thụ chính viên đạn đó** (loại khỏi `enemy_bullets`), đặt `shield: false`, `shield_expires_at: nil`, và **không** gọi `GameState.new_game_over/1`; nếu không có khiên, giữ nguyên hành vi hiện tại (game over ngay). Việc này đặt trong `Simulation.check_player_death/1` (hoặc bước mới `absorb_shield_hit/1` chạy **trước** `check_player_death/1` trong pipeline).

**Rationale**: Giữ nguyên luật một-hit-chết mặc định (constitution nguyên tắc V — không âm thầm nới lỏng độ khó vĩnh viễn); khiên chỉ là ngoại lệ có kiểm soát, tiêu hao ngay, khớp FR-008 và edge case "tương tác với độ khó tăng dần".

**Alternatives considered**:

- Khiên hấp thụ N lần trúng thay vì 1 — vượt phạm vi FR-008 ("đúng một lần trúng"); để dành cho spec sau nếu cần cân bằng lại.

---

## 6. Bảng tham số (`Powerups` module, giống vai trò `Difficulty`)

| Tham số | Giá trị MVP | Ghi chú |
|---|---|---|
| `drop_chance_pct` | 12 | % cơ hội rơi mỗi lần hạ địch |
| `rapid_fire_duration_ticks` | 300 (~15s @ 20Hz) | Thời hạn hiệu lực bắn nhanh |
| `rapid_fire_cooldown_ticks` | 5 (so với cơ bản 10) | Cooldown khi có `:rapid_fire` |
| `multi_shot_duration_ticks` | 300 (~15s @ 20Hz) | Thời hạn hiệu lực nhiều tia |
| `multi_shot_bullet_count` | 3 | Số viên đạn mỗi lần bắn khi có `:multi_shot` |
| `shield_duration_ticks` | 400 (~20s @ 20Hz) | Thời hạn nếu khiên không bị dùng tới |
| `max_falling_powerups` | 4 | Trần số powerup đang rơi cùng lúc (giữ payload nhỏ) |
| `powerup_fall_speed` | 2.4 | `vy` khi rơi (chậm hơn địch một chút để dễ né/nhặt) |

**Rationale**: Tách bảng tham số khỏi `Simulation` giống cách `Difficulty` đã làm ở 002 — dễ tinh chỉnh cân bằng mà không sửa pipeline.

---

## 7. Snapshot `frame` — trường mới

**Decision**: Thêm `powerups: Enum.map(g.powerups, &Map.take(&1, [:id, :x, :y, :w, :h, :kind]))` và `player_effects: %{rapid_fire: boolean, multi_shot: boolean, shield: boolean}` (rút gọn từ `active_effects`/`shield` — chỉ cờ hiện diện, không gửi tick tuyệt đối nội bộ ra client) vào `snapshot/1` khi `phase == :playing`. `kind` phải là string (`"rapid_fire"` / `"multi_shot"` / `"shield"`) vì Jason không cần atom nhưng để rõ ràng và nhất quán với cách encode hiện tại (atom key trong map con là ổn, atom **value** cũng encode được thành string bởi Jason — không cần ép kiểu thủ công, chỉ cần đảm bảo không phải tuple, theo đúng ghi chú JSON-safe hiện có trong `CLAUDE.md`).

**Rationale**: Tái khẳng định gotcha đã ghi trong `CLAUDE.md` (chỉ gửi field JSON-safe, không gửi tuple `:movement`-style) — áp dụng tương tự cho mọi field mới ở đây.
