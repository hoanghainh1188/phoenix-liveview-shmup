# Implementation Plan: Shmup — Hiệu ứng xác nhận trúng đạn

**Branch**: `006-shmup-hit-feedback` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-shmup-hit-feedback/spec.md`, extending the existing Phoenix app under `shmup/` (built on top of 001–005).

## Summary

Server phát sinh **sự kiện hạ địch nhất thời** (`kill_events: [%{x, y, kind}]`) mỗi tick trong `Simulation.resolve_hits/1`, tái dùng chính danh sách `killed` đã có sẵn từ `Collision.resolve_player_bullets_vs_enemies/3` (không đổi API). Trường này luôn được **gán lại** (không tích lũy) mỗi tick nên tự động rỗng ở các tick không có ai bị hạ — không cần thêm bước "reset" riêng. `GameLive.snapshot/1` gửi thêm `kill_events` trong payload `frame`. Toàn bộ hiệu ứng hình ảnh (nổ tại vị trí, nhấp nháy điểm) xử lý hoàn toàn trong `game_hook.js` bằng state cục bộ của client (không phải `%GameState{}`) — không ảnh hưởng luật chơi.

## Technical Context

**Language/Version**: Elixir (theo `shmup/mix.exs` và toolchain Mise trong repo) + JavaScript thuần trong `game_hook.js`.
**Primary Dependencies**: Phoenix + LiveView; asset pipeline mặc định; **không Ecto**.
**Storage**: Không thêm trạng thái lâu dài — `kill_events` là dữ liệu nhất thời trong `%GameState{}` (tồn tại đúng 1 tick), hiệu ứng nổ/nhấp nháy là state cục bộ JS không đồng bộ với server.
**Testing**: ExUnit cho `Simulation.resolve_hits/1` (kill_events đúng khi hạ địch, rỗng khi không có ai bị hạ, rỗng khi địch bị cull offscreen thay vì bị hạ, reset đúng ở `new_playing/0`). Không cần test JS tự động cho phần render — xác minh bằng quickstart thủ công (đúng mức độ hiện có của dự án, chưa có bộ test JS).
**Target Platform**: Trình duyệt desktop hiện đại; `mix phx.server` khi dev.
**Project Type**: Ứng dụng web Phoenix đơn (`shmup/`).
**Performance Goals**: Giữ tick **~20 Hz** (50 ms); `kill_events` mỗi tick bị giới hạn tự nhiên bởi số lượng địch tối đa trên màn hình, payload tăng thêm không đáng kể.
**Constraints**: Hiệu ứng hình ảnh **không được** phản hồi ngược lại state server (không `pushEvent` mới) — đây là lớp phản hồi một chiều, thuần túy trình bày.
**Scale/Scope**: Chỉ 3 user story trong spec (nổ khi hạ địch, nhấp nháy điểm, cường độ theo loại địch) — không thêm client-side prediction/reconciliation (đã loại trừ rõ trong Assumptions của spec).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Aligned with `.specify/memory/constitution.md` (Phoenix LiveView vertical shmup):

- [x] **LiveView-native surface**: Không đổi mô hình tick/`handle_info :tick`; chỉ mở rộng `snapshot/1` với một trường dữ liệu nhất thời thêm.
- [x] **Pure game core**: `kill_events` sinh ra thuần túy trong `Simulation.resolve_hits/1` từ dữ liệu đã có (`killed`), không import `Phoenix.LiveView`, không side-effect.
- [x] **Testing**: Test ExUnit cho việc sinh/reset `kill_events` trước khi đụng tới phần hiển thị JS.
- [x] **Performance**: Không đổi cadence ~20 Hz; payload tăng thêm tối thiểu (vài x/y/kind mỗi tick, giới hạn bởi max_enemies hiện có).
- [x] **Incremental scope**: Đây là lớp phản hồi hình ảnh thuần túy, không thay đổi luật chơi/kiến trúc server-authoritative — đúng phạm vi tối thiểu để giải quyết vấn đề người dùng báo cáo (nhầm lẫn do độ trễ), không mở rộng sang client-side prediction (đã cân nhắc và loại trừ rõ ràng ở bước hỏi người dùng trước khi lên spec).

**Post Phase 1**: Thiết kế thỏa constitution; không cần Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/006-shmup-hit-feedback/
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
│   ├── game_state.ex       # thêm kill_events: [] vào new_playing/0
│   └── simulation.ex       # resolve_hits/1 gán kill_events từ killed
├── lib/shmup_web/live/
│   └── game_live.ex        # snapshot: thêm kill_events JSON-safe
├── assets/
│   ├── css/app.css          # @keyframes cho hiệu ứng nhấp nháy điểm
│   └── js/hooks/game_hook.js # explosions[] cục bộ, vẽ + tự dọn; điểm nhấp nháy qua CSS class
└── test/shmup/game/
    └── simulation_test.exs  # tests kill_events sinh/reset đúng
```

**Structure Decision**: Tiếp tục một app Phoenix **`shmup/`** duy nhất; dữ liệu sự kiện sinh trong `Shmup.Game.*` như mọi feature trước, nhưng **hiệu ứng hiển thị hoàn toàn nằm ở client** (`game_hook.js`/`app.css`) — đây là feature đầu tiên có phần việc chính ở phía JS thay vì Elixir, vì bản chất là lớp trình bày phản hồi độ trễ, không phải luật chơi.

## Complexity Tracking

> Không có vi phạm constitution cần biện minh.
