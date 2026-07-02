# Implementation Plan: Shmup — Power-up và vũ khí nâng cấp

**Branch**: `003-shmup-powerups` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-shmup-powerups/spec.md`, extending the existing Phoenix app under `shmup/` (built on top of 001 core loop and 002 difficulty tiers).

## Summary

Thêm một lớp **vật phẩm rơi (powerup)** vào simulation thuần túy hiện có: khi địch bị hạ, có xác suất sinh một powerup rơi xuống (loại `:rapid_fire`, `:multi_shot`, hoặc `:shield`, chọn ngẫu nhiên đều); tàu người chơi chạm vào (AABB, tái dùng `Collision`) sẽ kích hoạt **hiệu lực đang hoạt động (active effect)** gắn trên `player`. `:rapid_fire` và `:multi_shot` có **thời hạn tính bằng `play_tick`**, tự hết hạn và có thể hoạt động **đồng thời** (kết hợp: nhiều tia + hồi chiêu nhanh hơn); nhặt trùng loại gia hạn thời hạn thay vì cộng dồn. `:shield` là cờ nhị phân + thời hạn: hấp thụ đúng một lần trúng đạn địch tiếp theo rồi tiêu hao, hoặc tự hết hạn nếu không dùng tới trước đó — không thay đổi luật game-over hiện có khi không có khiên. Toàn bộ nằm trong `Shmup.Game.*` (không proccess/side-effect mới); `GameLive` chỉ mở rộng `snapshot/1` để gửi thêm powerup đang rơi + trạng thái hiệu lực JSON-safe.

## Technical Context

**Language/Version**: Elixir (theo `shmup/mix.exs` và toolchain Mise trong repo).
**Primary Dependencies**: Phoenix + LiveView; asset pipeline mặc định; **không Ecto**.
**Storage**: Không lưu trạng thái powerup trên server ngoài process LiveView (giống 001/002).
**Testing**: ExUnit cho `Shmup.Game.*` (rơi vật phẩm theo xác suất/seed cố định trong test, va chạm nhặt, hết hạn hiệu lực, gia hạn, khiên hấp thụ đúng một lần); `Phoenix.LiveViewTest` smoke mở rộng nếu cần xác nhận snapshot chứa trường mới.
**Target Platform**: Trình duyệt desktop hiện đại; `mix phx.server` khi dev.
**Project Type**: Ứng dụng web Phoenix đơn (`shmup/`).
**Performance Goals**: Giữ tick **~20 Hz** (50 ms) như 001/002; số powerup đang rơi cùng lúc có **trần nhỏ** (ví dụ tối đa vài vật phẩm) để payload `frame` không phình to.
**Constraints**: Một nguồn sự thật trên server; xác suất rơi và tham số thời hạn phải **xác định được trong test** (không phụ thuộc `:rand` không seed được — dùng cơ chế tất định tương tự spawn hiện có, ví dụ dựa trên `tick`/`next_id`, hoặc factory test truyền tỉ lệ rõ ràng).
**Scale/Scope**: Một phiên LiveView; không thêm loại powerup ngoài 3 loại ở FR-004 cho MVP này (đúng tinh thần YAGNI của constitution).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Aligned with `.specify/memory/constitution.md` (Phoenix LiveView vertical shmup):

- [x] **LiveView-native surface**: Không đổi mô hình tick/`handle_info :tick`; `Simulation.step/1` vẫn là nguồn sự thật duy nhất; `GameLive` chỉ mở rộng `snapshot/1`.
- [x] **Pure game core**: Powerup rơi, va chạm nhặt, hiệu lực và thời hạn đều là hàm/state thuần túy trong `Shmup.Game.*`, không import `Phoenix.LiveView`.
- [x] **Testing**: Bảng test cho rơi vật phẩm (tất định), nhặt, hết hạn, gia hạn, khiên hấp thụ đúng một lần — trước khi đụng tới LiveView.
- [x] **Performance**: Giữ cadence ~20 Hz; trần số powerup đang rơi đồng thời (xem `research.md`) để payload `frame` nhỏ gọn.
- [x] **Incremental scope**: Constitution liệt kê power-up là mở rộng "advanced" *sau* vertical slice tối thiểu — 001 (core loop) và 002 (difficulty) đã hoàn thành và merge, nên đây đúng là bước tăng dần tiếp theo, không phải mở rộng phạm vi sớm. Giới hạn đúng 3 loại powerup ở P1–P3, không thêm cơ chế ngoài spec (không multiplayer, không lưu server-side).

**Post Phase 1**: Thiết kế thỏa constitution; không cần Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/003-shmup-powerups/
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
│   ├── game_state.ex       # player mở rộng active_effects/shield; state có powerups: []
│   ├── simulation.ex       # spawn powerup khi hạ địch (US1), fire theo hiệu lực (US2), tick/hết hạn hiệu lực, hấp thụ khiên (US3)
│   ├── physics.ex          # (không đổi hoặc chỉ thêm di chuyển powerup nếu tách khỏi collision)
│   ├── collision.ex        # va chạm player vs powerups; hấp thụ đạn địch khi có khiên
│   └── powerups.ex         # (mới) bảng tham số: tỉ lệ rơi, thời hạn hiệu lực, số tia multi_shot
├── lib/shmup_web/live/
│   └── game_live.ex        # snapshot: thêm powerups đang rơi + active_effects JSON-safe
├── assets/js/hooks/
│   └── game_hook.js         # vẽ powerup rơi; HUD tối thiểu hiệu lực đang hoạt động (debug text, giống difficulty_tier)
└── test/shmup/game/
    └── …                   # tests spawn powerup, pickup, expiry, refresh, shield absorb
```

**Structure Decision**: Tiếp tục một app Phoenix **`shmup/`** duy nhất; mọi luật powerup nằm trong `Shmup.Game.*` (module mới `powerups.ex` theo đúng vai trò `difficulty.ex` — bảng tham số thuần túy), điều phối/snapshot trong `GameLive`.

## Complexity Tracking

> Không có vi phạm constitution cần biện minh.
