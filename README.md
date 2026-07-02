# phoenix-liveview-shmup

A vertical scrolling shoot-'em-up (shmup) MVP built with Phoenix LiveView. The
game runs as a **server-authoritative simulation** inside a single LiveView
process (ticking at ~20 Hz); the browser only forwards throttled pointer/fire
input and renders each pushed frame to a `<canvas>` via a JS hook. High score is
kept client-side in `localStorage`. No database — scaffolded `--no-ecto`.

The Phoenix app lives in **`shmup/`**.

## Quick start

Toolchain is pinned via [mise](https://mise.jdx.dev/) (`.mise.toml`: Erlang 27.3.4.13,
Elixir 1.18.2-otp-27).

```bash
mise install        # once, at repo root
cd shmup
mix setup           # deps + assets
mix phx.server      # http://localhost:4000
```

Run the tests with `mix test` (from `shmup/`).

## Deploy (Render.com, free tier)

The app has no database and no persistent storage — a single Docker web
service is enough. `shmup/Dockerfile` and `render.yaml` (repo root) are
generated/configured for this.

1. Push this repo to GitHub (already done if you're reading this on GitHub).
2. In the Render dashboard: **New > Blueprint**, point it at this repo.
   Render reads `render.yaml` and provisions a free web service named
   `shmup` from `shmup/Dockerfile`, auto-generating `SECRET_KEY_BASE` and
   wiring `PHX_HOST` to the assigned `*.onrender.com` hostname.
3. Wait for the first build (a few minutes) — Render then serves the app at
   the assigned URL.

Free-tier tradeoff: the service spins down after ~15 minutes of inactivity
and cold-starts (a few seconds) on the next request. Since all game state
lives in the LiveView process and high scores are client-side
(`localStorage`), a spin-down loses nothing except in-progress games.

To verify the Docker build locally before pushing:

```bash
cd shmup
docker build -t shmup .
docker run --rm -p 8080:8080 \
  -e SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  -e PHX_HOST="localhost" \
  -e PHX_SERVER="true" \
  shmup
```

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
- **Deploy config**: [`render.yaml`](render.yaml), [`shmup/Dockerfile`](shmup/Dockerfile)
- **Feature 001 — start gameplay** (spec, plan, tasks, quickstart): [`specs/001-shmup-start-gameplay/`](specs/001-shmup-start-gameplay/)
- **Feature 002 — difficulty waves** (tiers, enemy fire, movement, HP): [`specs/002-shmup-difficulty-waves/`](specs/002-shmup-difficulty-waves/)
- **Feature 003 — power-ups** (drops, weapon upgrades, shield): [`specs/003-shmup-powerups/`](specs/003-shmup-powerups/)
- **Feature 004 — player health** (HP, invulnerability window): [`specs/004-shmup-player-health/`](specs/004-shmup-player-health/)
- **Feature 005 — enemy variety & boss** (tank enemies, periodic boss): [`specs/005-shmup-enemy-variety/`](specs/005-shmup-enemy-variety/)
