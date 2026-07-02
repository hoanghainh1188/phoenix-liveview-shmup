# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

- The Phoenix app lives in **`shmup/`** — all `mix` commands must run from that directory.
- `specs/` holds Spec Kit feature specs, plans, and tasks (`001-shmup-start-gameplay`, `002-shmup-difficulty-waves`). `.specify/` and `.cursor/skills/speckit-*` are the Spec Kit toolchain. Features are developed spec-first; read the relevant `specs/NNN-*/` folder before changing gameplay.
- `shmup/AGENTS.md` contains the authoritative Phoenix 1.8 / LiveView / HEEx usage rules for this codebase — follow them when writing any Elixir, template, or LiveView code.

## Toolchain

Erlang/Elixir are pinned via **mise** (`.mise.toml`: erlang 27.3.4.13, elixir 1.18.2-otp-27). Run `mise install` at the repo root before working. Erlang is pinned above 27.2 specifically because 27.2's `:ssl` rejects hex.pm's current Let's Encrypt certificate chain (`key_usage_mismatch`) — do not downgrade it.

## Commands

Run from `shmup/`:

```bash
mix setup          # deps.get + assets.setup + assets.build (first-time / after dep changes)
mix phx.server     # dev server at http://localhost:4000
mix test           # full suite
mix test test/shmup/game/physics_test.exs          # single file
mix test test/shmup/game/physics_test.exs:42        # single test at line
mix test --failed  # rerun last failures
mix precommit      # compile --warnings-as-errors + deps.unlock --unused + format + test — run before finishing changes
```

There is no database — the app is scaffolded `--no-ecto`. Do not add Ecto or a datastore for gameplay state.

## Architecture

The game is an **authoritative server-side simulation** driven by a single LiveView process. The browser only sends throttled input and renders frames it is pushed.

### Server tick loop (`ShmupWeb.GameLive`)

- One LiveView process per player holds the entire `%GameState{}` in a socket assign. No global game registry, no PubSub.
- On `"start"`, the LiveView schedules `:tick` every **50 ms (`@tick_ms`, ~20 Hz)** via `Process.send_after`. Each `handle_info(:tick, ...)` runs `Simulation.step/1`, reschedules the next tick, and pushes a `"frame"` event to the client. The loop self-terminates when phase becomes `:game_over` (no further tick scheduled).
- Client input arrives as `"input"` events (pointer `cx/cy` + `primary` fire flag) and is stored in `game.pending_input`; it is applied on the next simulation step, never processed inline.
- Phases: `:splash → :playing → :game_over`. Only `:playing` runs the simulation; other phases short-circuit.

### Pure game logic (`Shmup.Game.*`)

All simulation is pure functions over `%GameState{}` — no processes, no side effects. This is where gameplay logic belongs and what the unit tests target.

- `GameState` — the struct + constructors (`new_splash/0`, `new_playing/0`, `new_game_over/1`). Logical playfield is **480×640 game units** (`default_width/default_height`).
- `Simulation.step/1` — the ordered per-tick pipeline (advance time → apply input → cooldowns → spawn → player fire → move → enemy fire → resolve hits → cull offscreen → death check). Add new mechanics as a stage here.
- `Difficulty` — pure tier tables. A tier increases every `tier_period_ticks` (200 ticks = 10 s) up to `tier_max`. Spawn interval, max enemies, enemy fire cadence, and enemy HP are all functions of the tier. Tune balance here, not in `Simulation`.
- `Physics` — player clamping and per-enemy movement (`:straight`, `{:sine, ...}`, `{:composite, ...}` modes selected by tier in `Simulation.movement_for_tier/2`).
- `Collision` — AABB overlap and hit resolution (bullet consumed on hit; enemy HP decremented; score awarded only on kill).

**Coordinate convention:** every entity uses **center `(x, y)` with `w`/`h` as full width/height** (half-extents computed on use). This holds across `Collision`, `Physics`, and the JS renderer — keep it consistent.

### Client hook (`assets/js/hooks/game_hook.js`, `phx-hook="GameHook"`)

- Renders each pushed `"frame"` snapshot to `<canvas>` via 2D context; no game logic client-side.
- Throttles pointer input to `INPUT_INTERVAL_MS` (50 ms) to match the server tick and avoid flooding the channel.
- Owns the high score in `localStorage` (`shmup:high_score`); pushes it to the server as `client_high_score` for display and writes it back on `game_over`.
- The canvas is re-bound on every DOM patch (`syncCanvasToDom`) — the element is destroyed/recreated across phase transitions, so a cached node goes stale. The logical `GW/GH` constants (480/640) must stay in sync with `GameState.default_width/height`.

### Serialization gotcha

Enemy structs carry a `:movement` field that can be a **tuple** (e.g. `{:sine, ...}`), which **Jason cannot encode**. `GameLive.snapshot/1` sends only `@enemy_snapshot_keys` to the client (extended over time — check the current value in `game_live.ex` rather than assuming this doc's original list). If you add a client-visible enemy field, add it to that list — never push the raw enemy map through `push_event`.

## Deployment

`shmup/Dockerfile` (generated via `mix phx.gen.release --docker`) and `render.yaml` (repo root) deploy the app as a single Docker web service on Render.com's free tier — no database, no persistent volume needed. See the root `README.md` "Deploy" section for the click-through steps. If you change `mix.exs` deps or the Erlang/Elixir pins in `.mise.toml`, rebuild the Docker image locally (`cd shmup && docker build -t shmup .`) to confirm the release still compiles before pushing.
