---

description: "Task list for 004 shmup player health"
---

# Tasks: Shmup — Máu/mạng người chơi (004)

**Input**: Design documents from `/specs/004-shmup-player-health/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/liveview-hook-events.md](./contracts/liveview-hook-events.md)

**Tests**: Không có yêu cầu TDD trong spec — không tạo task test riêng; bước cuối gồm chạy `mix test` và quickstart. Constitution nguyên tắc III vẫn áp dụng: mọi module `Shmup.Game.*` chạm tới phải có test ExUnit tất định trước khi coi là hoàn tất.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể song song (file khác nhau, không chờ task chưa xong trong cùng file logic)
- **[USn]**: User story trong [spec.md](./spec.md)

## Path Conventions

- Ứng dụng Phoenix: `shmup/` (xem [plan.md](./plan.md))

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xác nhận môi trường và đường dẫn trùng plan.

- [ ] T001 Verify `shmup/mix.exs` exists and `cd shmup && mix compile` succeeds per `specs/004-shmup-player-health/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Bảng tham số máu và trường state chung — **bắt buộc xong trước các user story**.

**⚠️ CRITICAL**: Không triển khai US1–US3 cho đến khi phase này hoàn tất.

- [ ] T002 [P] Create `shmup/lib/shmup/game/health.ex` exporting parameter helpers (`max_hp/0`, `invulnerability_duration_ticks/0`) aligned with `specs/004-shmup-player-health/research.md` §7
- [ ] T003 [P] Extend `shmup/lib/shmup/game/game_state.ex`: add `hp: Health.max_hp()`, `max_hp: Health.max_hp()`, `invulnerable_until: nil` to the player map built in `new_playing/0` per `specs/004-shmup-player-health/data-model.md`

**Checkpoint**: Foundation ready — user story implementation can begin

---

## Phase 3: User Story 1 — Nhiều mạng thay vì chết ngay (Priority: P1) 🎯 MVP

**Goal**: Player có `hp`/`max_hp` nhiều hơn 1; trúng đạn (không khiên) trừ đúng 1 hp thay vì kết thúc ván ngay; game over chỉ khi hp về 0; giao diện hiển thị máu hiện tại.

**Independent Test**: Chơi một ván, cố ý trúng đạn nhiều lần cách nhau đủ lâu; xác nhận mỗi lần trừ đúng 1 hp và ván chỉ kết thúc khi hp về 0.

### Implementation for User Story 1

- [ ] T004 [US1] In `shmup/lib/shmup/game/simulation.ex`: add a new private stage `apply_damage/1`, called right after `absorb_shield/1` in `step/1`'s pipeline — when `Collision.enemy_hits_player?(s.enemy_bullets, s.player)` is true and the player is not currently invulnerable (see T007 for the invulnerability check, land as a no-op guard clause here first), decrement `player.hp` by 1 (floor at 0)
- [ ] T005 [US1] In `shmup/lib/shmup/game/simulation.ex`: replace `check_player_death/1`'s condition — it must now check `player.hp <= 0` instead of calling `Collision.enemy_hits_player?/2` directly (that check has moved into `apply_damage/1`)
- [ ] T006 [P] [US1] In `shmup/lib/shmup_web/live/game_live.ex`: add a "Máu: X/Y" line to the `:playing` branch of `render/1`, reading `@game.player.hp` / `@game.player.max_hp` directly from assigns (no snapshot/JS involvement needed for this line)

**Checkpoint**: User Story 1 delivers multi-hit survival with a visible HP counter (invulnerability not yet implemented — repeated bullets in the same tick may still over-trigger until Phase 4 lands, per research.md §3–4 the fix belongs there)

---

## Phase 4: User Story 2 — Khoảng bất tử ngắn sau khi trúng đạn (Priority: P2)

**Goal**: Sau khi mất hp, player bất tử một khoảng ngắn (`invulnerable_until`, tính bằng `play_tick`); trong lúc đó không trừ thêm hp; có tín hiệu hình ảnh (nhấp nháy) khi bất tử.

**Independent Test**: Trúng đạn, ngay sau đó lái vào luồng đạn khác trong khoảng bất tử; xác nhận không mất thêm máu cho tới khi hết bất tử.

### Implementation for User Story 2

- [ ] T007 [US2] In `shmup/lib/shmup/game/simulation.ex`: extend `apply_damage/1` (from T004) with the invulnerability guard — skip the hp decrement entirely (and leave `enemy_bullets` untouched) when `player.invulnerable_until` is set and `player.invulnerable_until > play_tick`; otherwise, on a hit, also set `invulnerable_until = play_tick + Health.invulnerability_duration_ticks()`
- [ ] T008 [P] [US2] In `shmup/lib/shmup_web/live/game_live.ex`: add `player_invulnerable` (boolean, derived from `player.invulnerable_until > g.play_tick`) to `snapshot/1`'s `:playing` branch per `specs/004-shmup-player-health/contracts/liveview-hook-events.md`
- [ ] T009 [P] [US2] In `shmup/assets/js/hooks/game_hook.js`: when `frame` payload has `player_invulnerable: true`, blink the player box (oscillate `ctx.globalAlpha` by `tick`/`play_tick` parity or a modulo) instead of drawing it fully opaque; reset `globalAlpha` to 1 afterward so it doesn't leak into other draws

**Checkpoint**: User Story 2 complete — invulnerability window prevents rapid-fire HP loss and is visually distinguishable

---

## Phase 5: User Story 3 — Khiên (003) vẫn hoạt động độc lập với máu (Priority: P3)

**Goal**: Xác nhận rõ ràng (qua test) rằng khiên hấp thụ đạn trước khi `apply_damage/1` thấy va chạm — không trừ hp, không kích hoạt bất tử khi có khiên.

**Independent Test**: Nhặt khiên, trúng đạn — hp không đổi, không nhấp nháy; trúng đạn lần kế tiếp (hết khiên, không bất tử) — trừ hp và kích hoạt bất tử bình thường.

### Implementation for User Story 3

- [ ] T010 [US3] Verify (no production code change expected — this task is a regression-safety checkpoint) that the pipeline order in `shmup/lib/shmup/game/simulation.ex`'s `step/1` keeps `absorb_shield/1` strictly before `apply_damage/1`, per `specs/004-shmup-player-health/data-model.md` — if T004/T007 landed in a different order, fix it here
- [ ] T011 [US3] Add ExUnit coverage in `shmup/test/shmup/game/simulation_test.exs` proving: shield absorption leaves `hp`/`invulnerable_until` unchanged for that tick, and a subsequent unshielded hit (no active shield, no invulnerability) decrements `hp` and activates invulnerability as usual

**Checkpoint**: User Story 3 complete — shield and HP systems compose correctly, verified by test

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Xác nhận regression toàn diện và quickstart.

- [ ] T012 [P] Ensure `GameState.new_playing/0` resets `hp`/`max_hp`/`invulnerable_until` to defaults every round (FR-010) — add/confirm an ExUnit assertion in `shmup/test/shmup/game/simulation_test.exs` alongside the existing 003 reset test
- [ ] T013 Run `cd shmup && mix test` and manual validation steps in `specs/004-shmup-player-health/quickstart.md`

---

## Dependencies & Execution Order

- **Phase 1 → Phase 2 → Phase 3 (US1)**: strictly sequential; US1 introduces `apply_damage/1` and the new `hp`-based death condition every later phase builds on.
- **Phase 4 (US2)**: depends on Phase 3 (extends the same `apply_damage/1` function with the invulnerability guard) — cannot start before T004/T005 land.
- **Phase 5 (US3)**: depends on Phase 4 (needs `invulnerable_until` to exist to assert it stays unset after a shielded hit) — primarily a verification/test phase, low implementation risk.
- **Phase 6**: depends on all prior phases.
- Within a phase, tasks marked `[P]` touch different files (or clearly separable regions of the same file) and can run in parallel; unmarked tasks in the same phase should be done in order because they build on the same function edited by a prior task.
