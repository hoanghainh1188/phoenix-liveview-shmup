# Implementation Plan: Shmup — Máu/mạng người chơi

**Branch**: `004-shmup-player-health` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-shmup-player-health/spec.md`, extending the existing Phoenix app under `shmup/` (built on top of 001 core loop, 002 difficulty tiers, and 003 power-ups/shield).

## Summary

Thay luật "trúng đạn = chết ngay" bằng **máu nhiều điểm (`hp`/`max_hp`)** trên player: trúng đạn địch (không khiên, không bất tử) trừ đúng 1 `hp` và kích hoạt **khoảng bất tử (`invulnerable_until`)** tính theo `play_tick`; game over chỉ xảy ra khi `hp` về 0. Khiên (003) tiếp tục hấp thụ hoàn toàn một lần trúng (không trừ `hp`, không kích hoạt bất tử). Toàn bộ nằm trong `Shmup.Game.*` thuần túy; `GameLive`/`game_hook.js` chỉ cần hiển thị `hp`/`max_hp` và tín hiệu nhấp nháy khi bất tử.

## Technical Context

**Language/Version**: Elixir (theo `shmup/mix.exs` và toolchain Mise trong repo).
**Primary Dependencies**: Phoenix + LiveView; asset pipeline mặc định; **không Ecto**.
**Storage**: Không lưu trạng thái máu trên server ngoài process LiveView (giống 001/002/003).
**Testing**: ExUnit cho `Shmup.Game.*` (trừ máu đúng 1 dù nhiều đạn trúng cùng tick, bất tử chặn trừ máu tiếp, hết bất tử trừ máu lại bình thường, khiên không trừ máu/không kích hoạt bất tử, game over đúng khi hp về 0, `new_playing/0` reset đúng).
**Target Platform**: Trình duyệt desktop hiện đại; `mix phx.server` khi dev.
**Project Type**: Ứng dụng web Phoenix đơn (`shmup/`).
**Performance Goals**: Giữ tick **~20 Hz** (50 ms) như các feature trước; không thêm entity mới cần render hàng loạt (chỉ thêm vài field số nguyên/boolean trên player).
**Constraints**: Một nguồn sự thật trên server; thứ tự pipeline phải đặt bước trừ máu **sau** bước hấp thụ khiên (003) đã có và **trước** bước kiểm tra game over, để khiên tiếp tục "chặn" hoàn toàn trước khi luật máu được xét tới.
**Scale/Scope**: Một phiên LiveView; `max_hp` và thời lượng bất tử là hằng số cố định cho MVP này (không có power-up hồi máu — đúng tinh thần YAGNI, để dành cho spec sau nếu cần).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Aligned with `.specify/memory/constitution.md` (Phoenix LiveView vertical shmup):

- [x] **LiveView-native surface**: Không đổi mô hình tick/`handle_info :tick`; `Simulation.step/1` vẫn là nguồn sự thật duy nhất; `GameLive` chỉ mở rộng render/snapshot cho `hp`/`max_hp`/bất tử.
- [x] **Pure game core**: Trừ máu, bất tử, tương tác khiên đều là hàm/state thuần túy trong `Shmup.Game.*`, không import `Phoenix.LiveView`.
- [x] **Testing**: Bảng test cho trừ máu đúng 1/tick, bất tử chặn trừ máu, hết hạn bất tử, khiên không kích hoạt bất tử, game over đúng lúc hp=0 — trước khi đụng tới LiveView.
- [x] **Performance**: Giữ cadence ~20 Hz; không thêm danh sách entity mới, chỉ vài trường trên player — không ảnh hưởng payload `frame`.
- [x] **Incremental scope**: Đây là thay đổi luật cốt lõi ("win/lose rules") mà constitution liệt kê trong vertical slice tối thiểu — 001 đã ship với luật one-hit-death đơn giản nhất có thể; 004 là bước tinh chỉnh lại luật đó sau khi 002/003 đã chứng minh nền tảng ổn định, không phải mở rộng phạm vi sớm. Không thêm power-up hồi máu, không thêm UI thanh máu phức tạp — giữ đúng phạm vi 3 user story trong spec.

**Post Phase 1**: Thiết kế thỏa constitution; không cần Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/004-shmup-player-health/
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
│   ├── game_state.ex       # player mở rộng hp/max_hp/invulnerable_until trong new_playing/0
│   ├── simulation.ex       # thay check_player_death bằng bước trừ máu + kích hoạt/hết hạn bất tử
│   ├── collision.ex        # (không đổi aabb_overlap?; enemy_hits_player?/absorb_shield_hit tái dùng nguyên trạng)
│   └── health.ex           # (mới) bảng tham số: max_hp, invulnerability_duration_ticks — giống vai trò Difficulty/Powerups
├── lib/shmup_web/live/
│   └── game_live.ex        # snapshot: thêm hp/max_hp/invulnerable JSON-safe; template hiển thị "Máu: X/Y"
├── assets/js/hooks/
│   └── game_hook.js         # nhấp nháy tàu khi invulnerable=true trong frame payload
└── test/shmup/game/
    └── …                   # tests trừ máu, bất tử, tương tác khiên, game over, reset ván mới
```

**Structure Decision**: Tiếp tục một app Phoenix **`shmup/`** duy nhất; mọi luật máu/bất tử nằm trong `Shmup.Game.*` (module mới `Health` theo đúng vai trò `Difficulty`/`Powerups` — bảng tham số thuần túy), điều phối/snapshot/hiển thị trong `GameLive`.

## Complexity Tracking

> Không có vi phạm constitution cần biện minh.
