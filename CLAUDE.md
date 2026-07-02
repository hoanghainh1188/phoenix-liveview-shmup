# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

- The Phoenix app lives in **`shmup/`** — all `mix` commands must run from that directory.
- `specs/` holds Spec Kit feature specs, plans, and tasks, one folder per feature: `001-shmup-start-gameplay` (core loop), `002-shmup-difficulty-waves` (tiers), `003-shmup-powerups` (power-up drops/shield), `004-shmup-player-health` (HP/invulnerability), `005-shmup-enemy-variety` (tank/boss). `.specify/` and `.cursor/skills/speckit-*` are the Spec Kit toolchain. Features are developed spec-first; read the relevant `specs/NNN-*/` folder before changing gameplay — each `plan.md`/`research.md` documents the parameter values and design tradeoffs, not just the `spec.md` requirements.
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

- `GameState` — the struct + constructors (`new_splash/0`, `new_playing/0`, `new_game_over/1`). Logical playfield is **480×640 game units** (`default_width/default_height`). `new_playing/0` is the single source of truth for what resets between rounds — every piece of per-round progress (power-up effects, HP, boss milestone tracking) **must** be reset there; a field left out here silently leaks state into the next game.
- `Simulation.step/1` — the ordered per-tick pipeline. Current order: advance time → maybe spawn boss → apply input → cooldowns → tick power-up/shield effects → maybe spawn regular enemy → fire player bullet → move everything → enemy fire → resolve hits (scoring + boss bonus + power-up drops) → resolve power-up pickup → cull offscreen → absorb shield hit → apply HP damage → check death. Read the actual `step/1` body before assuming this order — stages get inserted as features land, and pipeline **order encodes real dependencies** (e.g. shield absorption must run before HP damage, or a shielded hit would incorrectly cost HP too).
- `Difficulty` — pure tier tables. A tier increases every `tier_period_ticks` (200 ticks = 10 s) up to `tier_max`. Spawn interval, max enemies, enemy fire cadence, and enemy base HP are all functions of the tier. Tune spawn/HP balance here.
- `Enemies` — enemy **kind** selection and stats. `pick_kind/2` deterministically picks `:grunt` vs `:tank` from `(tier, id)` (a hash roll, not `:rand` — keeps spawns testable). `:tank` multiplies `Difficulty`'s base hp/speed/size. `:boss` spawns separately (`Simulation.maybe_spawn_boss/1`) once per `boss_tier_interval` tiers, tracked via `GameState.next_boss_tier`, and is the **one deliberate exception** allowed to exceed `Difficulty.max_enemies/1` so it's guaranteed to appear even on a full screen. Boss kills award a bonus added on top of the normal kill score in `Simulation.resolve_hits/1` — `Collision`'s scoring itself is untouched.
- `Powerups` — power-up parameters (drop chance, fall speed, per-kind duration/cooldown/bullet-count, max concurrent on screen). Drop kind is chosen deterministically from the killed enemy's `id` (same non-`:rand` pattern as `Enemies.pick_kind/2`, different hash multiplier so the two rolls don't correlate). Picking up a kind **refreshes** its expiry rather than stacking.
- `Health` — `max_hp` and `invulnerability_duration_ticks`. A hit costs 1 HP and starts an invulnerability window (tracked as an absolute `play_tick` deadline on `player.invulnerable_until`, same pattern as power-up expiries) during which further hits are ignored entirely — bullets are **not** consumed, they just pass through.
- `Physics` — player clamping and per-enemy movement (`:straight`, `{:sine, ...}`, `{:composite, ...}` modes selected by tier in `Simulation.movement_for_tier/2`). Applies uniformly regardless of `kind` — tank/boss just carry different size/speed/hp going into the same movement functions.
- `Collision` — AABB overlap and hit resolution: `resolve_player_bullets_vs_enemies/3` (bullet vs enemy, HP decrement, returns killed enemies for `Simulation` to react to), `resolve_player_vs_powerups/2`, `absorb_shield_hit/2` (shield consumes the bullet, no HP change), `enemy_hits_player?/2` (used by HP damage, not shield). Score/bonus math and power-up-kind selection live in `Simulation`, not here — `Collision` stays about geometry and HP only.

**Timed state uses absolute tick deadlines, not countdowns.** Power-up `active_effects` (003), `shield_expires_at` (003), and `player.invulnerable_until` (004) are all stored as `play_tick + duration` rather than a decrementing counter. Picking up the same effect again is then just reassigning the deadline (refresh, not stack). Follow this pattern for any new timed mechanic.

**Coordinate convention:** every entity uses **center `(x, y)` with `w`/`h` as full width/height** (half-extents computed on use). This holds across `Collision`, `Physics`, and the JS renderer — keep it consistent.

**Deterministic randomness convention:** anything that needs to look random but must stay testable (enemy kind, power-up drop chance/kind) uses `rem(id * <large hash multiplier>, 100)` against a fixed threshold — never `:rand`. Each system uses its own multiplier constant so rolls don't correlate across unrelated mechanics (see `Enemies.pick_kind/2` vs `Powerups`' drop roll in `Simulation`).

### Client hook (`assets/js/hooks/game_hook.js`, `phx-hook="GameHook"`)

- Renders each pushed `"frame"` snapshot to `<canvas>` via 2D context; no game logic client-side. All visual differentiation (enemy kind colors, power-up colors, invulnerability blink) is a pure function of fields already present in the snapshot — the client never infers game state on its own.
- Enemy color is looked up by `kind` (`grunt`/`tank`/`boss`, falling back to the grunt color for unknown kinds so an unrecognized future kind still renders instead of crashing). Power-up color is looked up by its `kind` the same way.
- Invulnerability renders as an alpha blink driven by `play_tick % 6` (server-driven parity, not a client-side timer) — see `player_invulnerable` in the frame payload.
- `player_effects`/`difficulty_tier` render as small debug-style text overlays on the canvas; HP (`player.hp`/`max_hp`) is rendered instead via the LiveView template/assigns (`GameLive.render/1`), not the canvas — it doesn't need per-tick redraw since LiveView diffing handles it.
- Throttles pointer input to `INPUT_INTERVAL_MS` (50 ms) to match the server tick and avoid flooding the channel.
- Owns the high score in `localStorage` (`shmup:high_score`); pushes it to the server as `client_high_score` for display and writes it back on `game_over`.
- The canvas is re-bound on every DOM patch (`syncCanvasToDom`) — the element is destroyed/recreated across phase transitions, so a cached node goes stale. The logical `GW/GH` constants (480/640) must stay in sync with `GameState.default_width/height`.
- **LiveView transport gotcha**: Phoenix LiveView's JS client falls back from WebSocket to long-poll and remembers that choice in `sessionStorage` (`phx:fallback:LongPoll`) for the rest of the browser tab's session — including across reloads. If WebSocket was broken once (e.g. a misconfigured `PHX_HOST` rejecting the origin) and got fixed later, an already-open tab stays stuck on the much slower long-poll transport until that `sessionStorage` key is cleared (or the tab is closed and reopened fresh). Symptom: `/live/longpoll` requests with repeated `503`s in the network tab instead of a single persistent WS connection. Worth checking first whenever "the game feels laggy" after a deploy fix.

### Serialization gotcha

Enemy structs carry a `:movement` field that can be a **tuple** (e.g. `{:sine, ...}`), which **Jason cannot encode**. `GameLive.snapshot/1` sends only `@enemy_snapshot_keys` to the client (extended over time — check the current value in `game_live.ex` rather than assuming this doc's original list; it currently includes `:kind`). The same rule applies to every other entity list added since (`powerups`) — always project through an explicit key allowlist, never push a raw internal map through `push_event`. `player` is sent whole (its fields are all plain maps/atoms/numbers, so it's already JSON-safe), but if you ever add a non-JSON-safe field to the player map, you'll need to start projecting it too.

## Deployment

`shmup/Dockerfile` (generated via `mix phx.gen.release --docker`) and `render.yaml` (repo root) deploy the app as a single Docker web service on Render.com's free tier — no database, no persistent volume needed. See the root `README.md` "Deploy" section for the click-through steps. If you change `mix.exs` deps or the Erlang/Elixir pins in `.mise.toml`, rebuild the Docker image locally (`cd shmup && docker build -t shmup .`) to confirm the release still compiles before pushing.

Two production issues already hit and fixed on this deployment, worth knowing before touching `render.yaml`/`config/runtime.exs` again:

- **`SECRET_KEY_BASE`**: Render's Blueprint `generateValue: true` produces a value shorter than the 64 bytes Phoenix's cookie store requires, crashing every request. `render.yaml` deliberately uses `sync: false` for it instead — it must be set manually from a real `mix phx.gen.secret` value in the Render dashboard.
- **`PHX_HOST` / WebSocket `check_origin`**: Phoenix's default `check_origin: true` rejects the LiveView socket unless the request's Origin header matches `config :shmup, ShmupWeb.Endpoint, url: [host: ...]`, which is driven by the `PHX_HOST` env var. If `PHX_HOST` doesn't exactly match the live Render hostname (e.g. `render.yaml`'s `fromService` binding didn't take), every socket connection fails and LiveView silently falls back to long-poll. **Do not "fix" this by widening `check_origin` to a wildcard** (e.g. `//*.onrender.com`) — Render is shared multi-tenant hosting, so that would let any other Render-hosted app hijack this app's WebSocket connections. The correct fix is verifying/setting `PHX_HOST` to the exact assigned hostname.
