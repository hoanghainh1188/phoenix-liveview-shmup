# phoenix-liveview-shmup

A vertical scrolling shoot-'em-up (shmup) MVP built with Phoenix LiveView. The
game runs as a **server-authoritative simulation** inside a single LiveView
process (ticking at ~20 Hz); the browser only forwards throttled pointer/fire
input and renders each pushed frame to a `<canvas>` via a JS hook. High score is
kept client-side in `localStorage`. No database — scaffolded `--no-ecto`.

The Phoenix app lives in **`shmup/`**.

## Quick start

Toolchain is pinned via [mise](https://mise.jdx.dev/) (`.mise.toml`: Erlang 27.2,
Elixir 1.18.2-otp-27).

```bash
mise install        # once, at repo root
cd shmup
mix setup           # deps + assets
mix phx.server      # http://localhost:4000
```

Run the tests with `mix test` (from `shmup/`).

## Project layout

```text
shmup/                 # Phoenix app (all mix commands run here)
  lib/shmup/game/      # pure simulation: GameState, Simulation, Difficulty, Physics, Collision
  lib/shmup_web/live/  # GameLive — server tick loop + snapshot push
  assets/js/hooks/     # game_hook.js — input throttle, canvas render, localStorage
specs/                 # Spec Kit feature specs, plans, and tasks
.specify/              # Spec Kit toolchain
```

## Docs

- **Architecture & dev guide**: [`CLAUDE.md`](CLAUDE.md)
- **App run / dev**: [`shmup/README.md`](shmup/README.md)
- **Feature 001 — start gameplay** (spec, plan, tasks, quickstart): [`specs/001-shmup-start-gameplay/`](specs/001-shmup-start-gameplay/)
- **Feature 002 — difficulty waves** (tiers, enemy fire, movement, HP): [`specs/002-shmup-difficulty-waves/`](specs/002-shmup-difficulty-waves/)
