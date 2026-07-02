# Implementation Plan: Shmup — Đa dạng địch và Boss

**Branch**: `005-shmup-enemy-variety` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-shmup-enemy-variety/spec.md`, extending the existing Phoenix app under `shmup/` (built on top of 001 core loop, 002 difficulty tiers, 003 power-ups, and 004 player health).

## Summary

Thêm trường `kind` (`:grunt` | `:tank` | `:boss`) lên địch. `:tank` chọn tất định từ `id` địch (giống mẫu xác suất đã dùng cho powerup ở 003), máu cao hơn và tốc độ chậm hơn `:grunt` cùng tier. `:boss` sinh **đúng một lần** mỗi khi `difficulty_tier` đạt mốc cố định (theo dõi bằng `next_boss_tier` trên `%GameState{}`), máu vượt trội, kích thước lớn, và khi hạ được cộng **điểm thưởng thêm** ngoài điểm giết thường (tính riêng trong `Simulation`, không đổi API `Collision`). Client vẽ màu/kích thước khác nhau theo `kind` (gửi thêm trong snapshot enemy). Toàn bộ nằm trong `Shmup.Game.*` thuần túy.

## Technical Context

**Language/Version**: Elixir (theo `shmup/mix.exs` và toolchain Mise trong repo).
**Primary Dependencies**: Phoenix + LiveView; asset pipeline mặc định; **không Ecto**.
**Storage**: Không lưu trạng thái ngoài process LiveView (giống 001–004).
**Testing**: ExUnit cho `Shmup.Game.*` (chọn kind tất định theo id/tier, tank có hp/tốc độ khác grunt, boss sinh đúng 1 lần mỗi mốc tier, boss hp vượt trội, boss cho điểm thưởng lớn hơn nhiều lần, `new_playing/0` reset `next_boss_tier`).
**Target Platform**: Trình duyệt desktop hiện đại; `mix phx.server` khi dev.
**Project Type**: Ứng dụng web Phoenix đơn (`shmup/`).
**Performance Goals**: Giữ tick **~20 Hz** (50 ms); boss là **ngoại lệ duy nhất** được phép vượt `max_enemies(tier)` (tối đa +1 địch tại đúng tick sinh boss) để đảm bảo luôn xuất hiện đúng mốc — mọi spawn thường khác vẫn tuân thủ trần như 002.
**Constraints**: Một nguồn sự thật trên server; việc chọn `kind` và mốc boss phải **tất định** để test được (không dùng `:rand` không seed).
**Scale/Scope**: Một phiên LiveView; chỉ 3 `kind` cố định cho MVP này (không thêm loại địch/đòn tấn công đặc biệt khác — đúng tinh thần YAGNI).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Aligned with `.specify/memory/constitution.md` (Phoenix LiveView vertical shmup):

- [x] **LiveView-native surface**: Không đổi mô hình tick/`handle_info :tick`; `Simulation.step/1` vẫn là nguồn sự thật duy nhất; `GameLive` chỉ mở rộng snapshot cho `kind`.
- [x] **Pure game core**: Chọn kind, sinh boss, tính điểm thưởng đều là hàm/state thuần túy trong `Shmup.Game.*`, không import `Phoenix.LiveView`.
- [x] **Testing**: Bảng test cho chọn kind tất định, tank hp/tốc độ, boss sinh đúng 1 lần/mốc, boss hp/điểm thưởng vượt trội, reset `next_boss_tier` — trước khi đụng tới LiveView.
- [x] **Performance**: Giữ cadence ~20 Hz; boss chỉ vượt trần `max_enemies` tối đa +1 tại đúng tick sinh, không tích luỹ.
- [x] **Incremental scope**: Constitution liệt kê boss là ví dụ "advanced" *sau* vertical slice tối thiểu — 001–004 đã hoàn thành, đây là bước tăng dần hợp lý tiếp theo. Chỉ 3 kind cố định, tái dùng nguyên hệ thống chuyển động/spawn/power-up đã có, không xây engine hành vi boss riêng.

**Post Phase 1**: Thiết kế thỏa constitution; không cần Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/005-shmup-enemy-variety/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── liveview-hook-events.md
└── tasks.md   # /speckit.tasks — không tạo bởi /speckit.plan
```

### Source Code (repository)

```text
shmup/
├── lib/shmup/game/
│   ├── game_state.ex       # thêm next_boss_tier vào GameState (new_playing/0)
│   ├── simulation.ex       # chọn kind khi spawn, sinh boss theo mốc tier, cộng điểm thưởng boss
│   ├── enemies.ex          # (mới) bảng tham số: kind hp/speed/size multipliers, boss_tier_interval, boss_hp_multiplier, boss_bonus_points, pick_kind/2
│   └── collision.ex        # (không đổi API — điểm cơ bản vẫn tính như cũ, bonus boss cộng riêng ở Simulation)
├── lib/shmup_web/live/
│   └── game_live.ex        # snapshot enemy thêm :kind (JSON-safe, atom → string)
├── assets/js/hooks/
│   └── game_hook.js         # vẽ màu/kích thước khác nhau theo enemy.kind
└── test/shmup/game/
    └── …                   # tests pick_kind, tank stats, boss spawn/mốc/điểm thưởng, reset ván mới
```

**Structure Decision**: Tiếp tục một app Phoenix **`shmup/`** duy nhất; bảng tham số mới `Enemies` theo đúng vai trò `Difficulty`/`Powerups`/`Health` đã có — mọi luật đa dạng địch/boss nằm trong `Shmup.Game.*`, điều phối/snapshot trong `GameLive`.

## Complexity Tracking

> Không có vi phạm constitution cần biện minh.
