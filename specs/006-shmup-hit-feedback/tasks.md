---

description: "Task list for 006 shmup hit feedback"
---

# Tasks: Shmup — Hiệu ứng xác nhận trúng đạn (006)

**Input**: Design documents from `/specs/006-shmup-hit-feedback/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/liveview-hook-events.md](./contracts/liveview-hook-events.md)

**Tests**: Không có yêu cầu TDD trong spec — không tạo task test riêng; bước cuối gồm chạy `mix test` và quickstart. Constitution nguyên tắc III vẫn áp dụng cho phần Elixir (`kill_events` sinh/reset đúng phải có test ExUnit); phần JS xác minh thủ công theo quickstart (dự án chưa có bộ test JS tự động).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Có thể song song (file khác nhau, không chờ task chưa xong trong cùng file logic)
- **[USn]**: User story trong [spec.md](./spec.md)

## Path Conventions

- Ứng dụng Phoenix: `shmup/` (xem [plan.md](./plan.md))

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Xác nhận môi trường và đường dẫn trùng plan.

- [ ] T001 Verify `shmup/mix.exs` exists and `cd shmup && mix compile` succeeds per `specs/006-shmup-hit-feedback/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Trường state chung cho sự kiện hạ địch — **bắt buộc xong trước các user story**.

**⚠️ CRITICAL**: Không triển khai US1–US3 cho đến khi phase này hoàn tất.

- [ ] T002 [P] Extend `shmup/lib/shmup/game/game_state.ex`: add `kill_events: []` to `new_playing/0` per `specs/006-shmup-hit-feedback/data-model.md`

**Checkpoint**: Foundation ready — user story implementation can begin

---

## Phase 3: User Story 1 — Hiệu ứng nổ tại vị trí hạ địch thật sự (Priority: P1) 🎯 MVP

**Goal**: Server phát sinh `kill_events` mỗi tick từ `killed` đã có; client vẽ hiệu ứng nổ tại đúng vị trí, tự biến mất sau thời gian ngắn; địch cull offscreen không kích hoạt hiệu ứng.

**Independent Test**: Hạ một địch — thấy nổ đúng vị trí, tự biến mất; để địch trôi hết màn hình mà không bắn trúng — không có hiệu ứng nào.

### Implementation for User Story 1

- [ ] T003 [US1] In `shmup/lib/shmup/game/simulation.ex`: in `resolve_hits/1`, add `kill_events: Enum.map(killed, &Map.take(&1, [:x, :y, :kind]))` to the returned state (reusing the existing `killed` list from `Collision.resolve_player_bullets_vs_enemies/3` — no change to `Collision`'s signature)
- [ ] T004 [P] [US1] In `shmup/lib/shmup_web/live/game_live.ex`: add `kill_events: g.kill_events` to `snapshot/1`'s `:playing` branch per `specs/006-shmup-hit-feedback/contracts/liveview-hook-events.md`
- [ ] T005 [US1] In `shmup/assets/js/hooks/game_hook.js`: add an `EXPLOSION_LIFETIME_MS` constant and `this.explosions = []` initialized in `mounted()`; in `draw(p)`, push a new `{x, y, kind, bornAt: performance.now()}` entry for each item in `p.kill_events`, then filter out entries older than `EXPLOSION_LIFETIME_MS`, then render each remaining explosion (radius/alpha interpolated by age) using the existing `enemyColors` lookup by `kind` for consistency with enemy rendering

**Checkpoint**: User Story 1 delivers a clear visual confirmation exactly when and where a real server-confirmed kill happens

---

## Phase 4: User Story 2 — Số điểm nhấp nháy khi tăng (Priority: P2)

**Goal**: Dòng "Điểm" trong LiveView template có hiệu ứng nổi bật ngắn mỗi khi điểm số tăng.

**Independent Test**: Hạ một địch, quan sát dòng "Điểm" — có nhấp nháy ngắn rồi trở lại bình thường; điểm không đổi thì không nhấp nháy.

### Implementation for User Story 2

- [ ] T006 [US2] In `shmup/lib/shmup_web/live/game_live.ex`: add `id="score-value"` to the `<span>` displaying `@game.score` in the `:playing` branch of `render/1`
- [ ] T007 [P] [US2] In `shmup/assets/css/app.css`: add a `@keyframes score-pulse` animation (brief scale/color highlight, ~300–400ms) and a `.score-pulse` class applying it — plain CSS, no `@apply` per repo convention
- [ ] T008 [US2] In `shmup/assets/js/hooks/game_hook.js`: add `this._lastScore = 0` initialized in `mounted()`; in `draw(p)`, when `p.score > this._lastScore`, look up `this.el.querySelector("#score-value")`, remove then re-add the `score-pulse` class (with a forced reflow, e.g. reading `el.offsetWidth`, so the animation restarts on rapid consecutive triggers) — then unconditionally set `this._lastScore = p.score` at the end of `draw(p)`

**Checkpoint**: User Story 2 complete — score increases have an independent, hard-to-miss visual signal

---

## Phase 5: User Story 3 — Cường độ hiệu ứng phản ánh loại địch (Priority: P3)

**Goal**: Hiệu ứng nổ khi hạ `:boss` rõ ràng lớn hơn/nổi bật hơn `:grunt`/`:tank`.

**Independent Test**: Hạ một grunt và một boss (trong cùng ván hoặc so sánh riêng) — hiệu ứng boss rõ ràng to hơn.

### Implementation for User Story 3

- [ ] T009 [US3] In `shmup/assets/js/hooks/game_hook.js`: extend the explosion rendering from T005 with a per-`kind` max-radius table (`grunt: 18, tank: 26, boss: 45`, matching `research.md` §4) so the rendered explosion size scales with the kind of the killed enemy

**Checkpoint**: User Story 3 complete — boss kills feel proportionally bigger, reinforcing their score bonus

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Reset đúng khi vào ván mới, xác nhận regression, quickstart.

- [ ] T010 [US1] [US2] In `shmup/assets/js/hooks/game_hook.js`'s `updated()`: detect transition **into** `:playing` (mirroring the existing splash-transition detection pattern) and reset `this.explosions = []` and `this._lastScore = 0` there, so a new round never inherits leftover explosions or a stale score baseline from the previous game (per `research.md` §6 and spec edge cases)
- [ ] T011 [P] Add ExUnit coverage in `shmup/test/shmup/game/simulation_test.exs` for: `kill_events` contains the killed enemy's `x`/`y`/`kind` when a kill happens, `kill_events == []` when nothing was killed that tick, and an enemy culled offscreen (never reaching hp 0) never appears in `kill_events`
- [ ] T012 [P] Confirm `GameState.new_playing/0` resets `kill_events` to `[]` — add/confirm an assertion in the existing reset test in `simulation_test.exs`
- [ ] T013 Run `cd shmup && mix test` and manual validation steps in `specs/006-shmup-hit-feedback/quickstart.md`

---

## Dependencies & Execution Order

- **Phase 1 → Phase 2 → Phase 3 (US1)**: strictly sequential; US1 introduces `kill_events` and the client explosion renderer every later phase builds on.
- **Phase 4 (US2)**: independent of Phase 3's explosion mechanics (different DOM element, different data source — `p.score` vs `p.kill_events`) — could technically run in parallel with Phase 3, but is sequenced after here since both touch `game_hook.js`'s `draw(p)` and are easier to review one at a time.
- **Phase 5 (US3)**: depends on Phase 3 (extends the same explosion renderer with per-kind sizing).
- **Phase 6**: depends on all prior phases (the reset logic touches state introduced by both US1 and US2).
- Within a phase, tasks marked `[P]` touch different files (or clearly separable regions of the same file) and can run in parallel; unmarked tasks in the same phase should be done in order because they build on the same function edited by a prior task.
