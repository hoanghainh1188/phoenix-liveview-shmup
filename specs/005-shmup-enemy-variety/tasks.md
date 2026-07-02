---

description: "Task list for 005 shmup enemy variety and boss"
---

# Tasks: Shmup — Đa dạng địch và Boss (005)

**Input**: Design documents from `/specs/005-shmup-enemy-variety/`
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

- [ ] T001 Verify `shmup/mix.exs` exists and `cd shmup && mix compile` succeeds per `specs/005-shmup-enemy-variety/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Bảng tham số địch/boss và trường state chung — **bắt buộc xong trước các user story**.

**⚠️ CRITICAL**: Không triển khai US1–US3 cho đến khi phase này hoàn tất.

- [ ] T002 [P] Create `shmup/lib/shmup/game/enemies.ex` exporting parameter helpers (`tank_min_tier/0`, `tank_chance_pct/0`, `tank_hp_multiplier/0`, `tank_speed_multiplier/0`, `tank_size_multiplier/0`, `boss_tier_interval/0`, `boss_hp_multiplier/0`, `boss_bonus_points/0`, `boss_width/0`, `boss_height/0`) and `pick_kind/2` aligned with `specs/005-shmup-enemy-variety/research.md` §1, §8
- [ ] T003 [P] Extend `shmup/lib/shmup/game/game_state.ex`: add `next_boss_tier: Enemies.boss_tier_interval()` to `new_playing/0` per `specs/005-shmup-enemy-variety/data-model.md`
- [ ] T004 [P] Update existing test fixtures that build enemy maps by hand (e.g. `static_enemy/2` in `shmup/test/shmup/game/simulation_test.exs`) to include `kind: :grunt` so pre-005 tests keep passing once code reads `enemy.kind`

**Checkpoint**: Foundation ready — user story implementation can begin

---

## Phase 3: User Story 1 — Ít nhất hai loại địch thường khác nhau (Priority: P1) 🎯 MVP

**Goal**: Địch sinh ra có `kind` (`:grunt` hoặc `:tank`) chọn tất định theo tier/id; `:tank` có hp cao hơn, chậm hơn, to hơn cùng tier.

**Independent Test**: Chơi đủ lâu để vượt `tank_min_tier`; quan sát ít nhất hai kích thước/tốc độ khác nhau; xác nhận tank cần nhiều phát trúng hơn.

### Implementation for User Story 1

- [ ] T005 [US1] In `shmup/lib/shmup/game/simulation.ex`: in `spawn_one_enemy/1`, call `Enemies.pick_kind(tier, id)` and branch enemy construction — `:grunt` keeps existing hp/size/vy; `:tank` multiplies `Difficulty.enemy_hp(tier)` by `Enemies.tank_hp_multiplier/0`, `vy` by `Enemies.tank_speed_multiplier/0`, and `w`/`h` by `Enemies.tank_size_multiplier/0` (rounded); both set `kind` on the enemy map
- [ ] T006 [P] [US1] In `shmup/lib/shmup_web/live/game_live.ex`: add `:kind` to `@enemy_snapshot_keys` per `specs/005-shmup-enemy-variety/contracts/liveview-hook-events.md`

**Checkpoint**: User Story 1 delivers observable grunt/tank variety with correct relative HP and speed (boss not yet implemented)

---

## Phase 4: User Story 2 — Boss xuất hiện định kỳ theo tier (Priority: P2)

**Goal**: Boss sinh đúng một lần mỗi khi `difficulty_tier` vượt `next_boss_tier`; hp vượt trội (vượt cả `max_enemies` cap tại đúng tick đó); hạ boss cộng điểm thưởng lớn.

**Independent Test**: Chơi vượt tier 5; xác nhận đúng một boss xuất hiện, hp/kích thước vượt trội, và hạ được cho điểm nhảy vọt.

### Implementation for User Story 2

- [ ] T007 [US2] In `shmup/lib/shmup/game/simulation.ex`: add a new private stage `maybe_spawn_boss/1`, called in `step/1` right after `advance_play_time/1` — when `s.difficulty_tier >= s.next_boss_tier`, prepend a new enemy with `kind: :boss`, `id: s.next_id`, `x: s.width / 2`, `y: 30.0`, `w: Enemies.boss_width/0`, `h: Enemies.boss_height/0`, `hp: round(Difficulty.enemy_hp(tier) * Enemies.boss_hp_multiplier/0)`, movement from the existing `movement_for_tier/2`, unconditionally (bypassing `Difficulty.max_enemies/1` per `research.md` §4); bump `next_id` and set `next_boss_tier = next_boss_tier + Enemies.boss_tier_interval/0`
- [ ] T008 [US2] In `shmup/lib/shmup/game/simulation.ex`: extend `resolve_hits/1` — after the existing base-score addition from `Collision.resolve_player_bullets_vs_enemies/3`'s `killed` list, add `Enemies.boss_bonus_points/0` to `state.score` for each killed enemy with `kind == :boss` (no change to `Collision`'s signature or behavior)

**Checkpoint**: User Story 2 complete — boss spawns exactly once per tier milestone with outsized HP and score reward

---

## Phase 5: User Story 3 — Phân biệt trực quan các loại địch (Priority: P3)

**Goal**: Client vẽ màu khác nhau theo `enemy.kind` (grunt tím, tank cam, boss đỏ), boss nổi bật rõ rệt.

**Independent Test**: Quan sát màn hình khi có đủ loại địch; phân biệt được bằng mắt không cần đọc số liệu debug.

### Implementation for User Story 3

- [ ] T009 [US3] In `shmup/assets/js/hooks/game_hook.js`: replace the flat `drawBox(e, "#a78bfa")` call for `p.enemies` with a per-kind color lookup (`grunt: "#a78bfa"`, `tank: "#f97316"`, `boss: "#ef4444"`, fallback to the existing purple for unknown/missing `kind`)

**Checkpoint**: User Story 3 complete — enemy kinds are visually distinguishable at a glance

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Xác nhận regression toàn diện và quickstart.

- [ ] T010 [P] Add ExUnit coverage in `shmup/test/shmup/game/enemies_test.exs` for `Enemies` parameter sanity and `pick_kind/2` determinism (same tier/id always yields the same kind; below `tank_min_tier` always yields `:grunt`)
- [ ] T011 [P] Add ExUnit coverage in `shmup/test/shmup/game/simulation_test.exs` for: tank hp/speed/size vs. grunt at the same tier, boss spawning exactly once at a tier milestone (not spawning again before the next milestone), boss score bonus applied on top of the base kill score, and `GameState.new_playing/0` resetting `next_boss_tier`
- [ ] T012 Run `cd shmup && mix test` and manual validation steps in `specs/005-shmup-enemy-variety/quickstart.md`

---

## Dependencies & Execution Order

- **Phase 1 → Phase 2 → Phase 3 (US1)**: strictly sequential; US1 introduces `kind` on enemies that every later phase depends on.
- **Phase 4 (US2)**: depends on Phase 3 (`kind` field must exist; boss is "just another kind" reusing the same enemy shape) — cannot start before T005 lands.
- **Phase 5 (US3)**: depends on Phase 3's snapshot change (T006) for `kind` to reach the client — independent of Phase 4's boss logic itself, but boss's visual distinctness is only meaningful once US2 can actually spawn one.
- **Phase 6**: depends on all prior phases.
- Within a phase, tasks marked `[P]` touch different files (or clearly separable regions of the same file) and can run in parallel; unmarked tasks in the same phase should be done in order because they build on the same function edited by a prior task.
