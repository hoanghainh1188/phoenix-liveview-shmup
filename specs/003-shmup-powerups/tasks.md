---

description: "Task list for 003 shmup power-ups"
---

# Tasks: Shmup — Power-up và vũ khí nâng cấp (003)

**Input**: Design documents from `/specs/003-shmup-powerups/`
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

- [ ] T001 Verify `shmup/mix.exs` exists and `cd shmup && mix compile` succeeds per `specs/003-shmup-powerups/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Bảng tham số powerup và trường state chung — **bắt buộc xong trước các user story**.

**⚠️ CRITICAL**: Không triển khai US1–US3 cho đến khi phase này hoàn tất.

- [ ] T002 [P] Create `shmup/lib/shmup/game/powerups.ex` exporting parameter helpers (`drop_chance_pct/0`, `max_falling_powerups/0`, `fall_speed/0`, `rapid_fire_duration_ticks/0`, `rapid_fire_cooldown_ticks/0`, `multi_shot_duration_ticks/0`, `multi_shot_bullet_count/0`, `shield_duration_ticks/0`) aligned with `specs/003-shmup-powerups/research.md` §6
- [ ] T003 [P] Extend `shmup/lib/shmup/game/game_state.ex`: add `powerups: []` and `next_powerup_id: 1` to `GameState`; add `active_effects: %{}`, `shield: false`, `shield_expires_at: nil` to the player map built in `new_playing/0` per `specs/003-shmup-powerups/data-model.md`

**Checkpoint**: Foundation ready — user story implementation can begin

---

## Phase 3: User Story 1 — Địch rơi vật phẩm khi bị hạ (Priority: P1) 🎯 MVP

**Goal**: Hạ địch có xác suất tất định sinh powerup rơi tại vị trí địch; tàu chạm vào (AABB) thì nhặt (powerup biến mất khỏi state); rơi khỏi đáy màn hình mà không nhặt thì biến mất không hiệu lực.

**Independent Test**: Chơi một ván, hạ nhiều địch liên tiếp; xác nhận thỉnh thoảng có vật phẩm rơi, và lái tàu chạm vào khiến nó biến mất khỏi `powerups`.

### Implementation for User Story 1

- [ ] T004 [US1] In `shmup/lib/shmup/game/simulation.ex`: in `resolve_hits/1` (or a new stage called right after it), when an enemy's `hp` reaches ≤ 0 in that step, compute a deterministic roll from the killed enemy's `id` (per `research.md` §1) against `Powerups.drop_chance_pct/0`; if it hits and `length(state.powerups) < Powerups.max_falling_powerups/0`, prepend a new `%{id, x, y, w: _, h: _, vy: Powerups.fall_speed(), kind}` powerup (kind chosen deterministically from the enemy id per research §1), incrementing `next_powerup_id`
- [ ] T005 [P] [US1] In `shmup/lib/shmup/game/simulation.ex`: `move_all/1` — advance each powerup's `y` by its `vy` each tick (same pattern as bullets)
- [ ] T006 [P] [US1] In `shmup/lib/shmup/game/collision.ex`: add `resolve_player_vs_powerups/2` (or similar) that returns `{kept_powerups, picked_up_kinds}` using `aabb_overlap?/2` between player and each powerup; wire into `Simulation.step/1` so a pickup removes the powerup from `state.powerups` and applies the effect described in Phase 4/5 (activation applies even before those phases land — implement pickup plumbing here, effect activation itself lands with US2/US3)
- [ ] T007 [P] [US1] In `shmup/lib/shmup/game/simulation.ex`: `cull_offscreen/1` — filter `powerups` using the same `y < h + 80` threshold as enemies
- [ ] T008 [P] [US1] In `shmup/lib/shmup_web/live/game_live.ex`: add `powerups` (mapped to JSON-safe keys `[:id, :x, :y, :w, :h, :kind]`) to `snapshot/1` per `specs/003-shmup-powerups/contracts/liveview-hook-events.md`

**Checkpoint**: User Story 1 delivers observable drop + pickup mechanic (no gameplay effect required to be visible yet)

---

## Phase 4: User Story 2 — Tăng tốc độ bắn và bắn nhiều tia (Priority: P2)

**Goal**: Nhặt `:rapid_fire` giảm cooldown bắn; nhặt `:multi_shot` bắn nhiều viên tỏa hướng; cả hai có thời hạn theo `play_tick`, gia hạn khi nhặt trùng loại, kết hợp được với nhau, và tự hết hạn.

**Independent Test**: Nhặt vật phẩm tăng tốc độ bắn, xác nhận khoảng cách giữa các viên đạn ngắn lại; nhặt vật phẩm bắn nhiều tia, xác nhận mỗi lần bắn ra nhiều hơn một viên; đợi hết thời hạn, xác nhận quay lại cơ bản.

### Implementation for User Story 2

- [ ] T009 [US2] In `shmup/lib/shmup/game/simulation.ex`: when a pickup from US1 resolves to `:rapid_fire` or `:multi_shot`, set `player.active_effects[kind] = play_tick + duration(kind)` (assign, not accumulate — refresh semantics per `research.md` §2–3)
- [ ] T010 [US2] In `shmup/lib/shmup/game/simulation.ex`: add an expiry stage (new private function, called each tick from `step/1` while `:playing`) that drops any `active_effects` entry whose `expires_at_tick <= play_tick`
- [ ] T011 [US2] In `shmup/lib/shmup/game/simulation.ex`: update `fire_player_bullet/1` — cooldown becomes `Powerups.rapid_fire_cooldown_ticks/0` when `Map.has_key?(player.active_effects, :rapid_fire)`, else the existing `@player_fire_cooldown`; bullet count becomes `Powerups.multi_shot_bullet_count/0` (fanned `vx` offsets, same `vy`) when `Map.has_key?(player.active_effects, :multi_shot)`, else the existing single straight bullet — both conditions independent so they combine naturally (FR-007)

**Checkpoint**: User Story 2 complete — rapid_fire and multi_shot are pickable, timed, refreshable, and combinable

---

## Phase 5: User Story 3 — Khiên tạm thời (Priority: P3)

**Goal**: Nhặt `:shield` đặt `player.shield = true` với thời hạn; đạn địch trúng khi có khiên bị hấp thụ (tiêu hao khiên, không kết thúc ván); không có khiên thì hành vi cũ (game over) không đổi; khiên cũng tự hết hạn nếu không dùng tới.

**Independent Test**: Nhặt khiên, để trúng một viên đạn địch — ván không kết thúc và khiên biến mất; trúng đạn lần kế tiếp (không còn khiên) — ván kết thúc như luật hiện có.

### Implementation for User Story 3

- [ ] T012 [US3] In `shmup/lib/shmup/game/simulation.ex`: when a pickup from US1 resolves to `:shield`, set `player.shield = true`, `player.shield_expires_at = play_tick + Powerups.shield_duration_ticks/0` (refresh if already active, per `research.md` §3)
- [ ] T013 [US3] In `shmup/lib/shmup/game/simulation.ex`: extend the expiry stage from T010 to also clear `shield`/`shield_expires_at` back to `false`/`nil` when `shield_expires_at <= play_tick`
- [ ] T014 [US3] In `shmup/lib/shmup/game/collision.ex`: add `absorb_shield_hit/1` (or extend the existing enemy-bullet-vs-player check) that, when `player.shield == true` and an enemy bullet overlaps the player, removes that bullet from `enemy_bullets` and clears `shield`/`shield_expires_at`, returning enough info for `Simulation` to skip `check_player_death/1` for that tick
- [ ] T015 [US3] In `shmup/lib/shmup/game/simulation.ex`: wire T014 into `step/1` **before** `check_player_death/1` so an absorbed hit never reaches the death check that tick (per `data-model.md` "Va chạm — mở rộng luật hiện có")

**Checkpoint**: User Story 3 complete — shield absorbs exactly one hit, expires if unused, and never inherits across games (FR-009, verified by T003's `new_playing/0` reset)

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Snapshot HUD tối thiểu, xác nhận regression và quickstart.

- [ ] T016 [P] In `shmup/lib/shmup_web/live/game_live.ex`: add `player_effects` (`%{rapid_fire: boolean, multi_shot: boolean, shield: boolean}` derived from `active_effects`/`shield`) to `snapshot/1` per contracts
- [ ] T017 [P] Optionally render falling powerups and active-effect indicators in `shmup/assets/js/hooks/game_hook.js` when the `frame` payload includes `powerups`/`player_effects` (debug-text style, matching the existing `difficulty_tier` HUD line)
- [ ] T018 Run `cd shmup && mix test` and manual validation steps in `specs/003-shmup-powerups/quickstart.md`

---

## Dependencies & Execution Order

- **Phase 1 → Phase 2 → Phase 3 (US1)**: strictly sequential; US1 is the foundation every other story's pickup plumbing depends on.
- **Phase 4 (US2) and Phase 5 (US3)**: both depend on Phase 3 (pickup detection) but are independent of each other — can be implemented in either order, or in parallel by different contributors, since they touch disjoint effect kinds (`active_effects` map vs. `shield` fields) even though they land in the same files.
- **Phase 6**: depends on all prior phases (needs final `powerups`/`player_effects` shapes to snapshot).
- Within a phase, tasks marked `[P]` touch different files (or clearly separable regions of the same file) and can run in parallel; unmarked tasks in the same phase should be done in order because they build on the same function edited by a prior task.
