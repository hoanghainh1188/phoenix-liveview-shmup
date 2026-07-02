// LiveView hook: real-time pointer + fire input, canvas render, local high score.

const STORAGE_KEY = "shmup:high_score"
const GW = 480
const GH = 640
// Match server tick (~20 Hz) — avoid flooding the LiveView channel with 60 input events/sec.
const INPUT_INTERVAL_MS = 50

export const GameHook = {
  mounted() {
    this.canvas = null
    this.ctx = null
    this.pending = { cx: GW / 2, cy: GH - 60, primary: false }
    this.raf = null
    this._prevPhase = this.el.dataset.phase
    this._lastInputSent = 0

    this.onMove = (e) => this.trackPointer(e)
    this.onDown = () => {
      this.pending.primary = true
    }
    this.onUp = () => {
      this.pending.primary = false
    }

    window.addEventListener("mousemove", this.onMove)
    window.addEventListener("mousedown", this.onDown)
    window.addEventListener("mouseup", this.onUp)

    this.handleEvent("frame", (payload) => this.draw(payload))
    this.handleEvent("phase", (payload) => this.onPhase(payload))

    // Defer until LiveView channel is ready (avoids rare "push before join" console noise).
    requestAnimationFrame(() => {
      this.pushEvent("client_high_score", { value: readHighScore() })
    })

    this.loop = () => {
      const ph = this.el.dataset.phase
      if (ph === "playing") {
        this.syncCanvasToDom()
        const now = performance.now()
        if (now - this._lastInputSent >= INPUT_INTERVAL_MS) {
          this._lastInputSent = now
          this.pushEvent("input", {
            cx: this.pending.cx,
            cy: this.pending.cy,
            primary: this.pending.primary
          })
        }
      }
      this.raf = requestAnimationFrame(this.loop)
    }
    this.raf = requestAnimationFrame(this.loop)
  },

  updated() {
    this.syncCanvasToDom()
    const phase = this.el.dataset.phase
    // Only when *entering* splash from another phase (e.g. game over → menu).
    // Do not fire on every splash re-render — that caused an assign↔push loop and console errors.
    if (phase === "splash" && this._prevPhase !== "splash") {
      this.pushEvent("client_high_score", { value: readHighScore() })
    }
    this._prevPhase = phase
  },

  destroyed() {
    if (this.raf) cancelAnimationFrame(this.raf)
    window.removeEventListener("mousemove", this.onMove)
    window.removeEventListener("mousedown", this.onDown)
    window.removeEventListener("mouseup", this.onUp)
  },

  /**
   * Re-bind canvas whenever DOM is patched (e.g. splash → playing again).
   * Stale `this.canvas` pointing at a detached node caused a blank screen on second run.
   */
  syncCanvasToDom() {
    const c = this.el.querySelector("#game-canvas")
    if (!c) {
      this.canvas = null
      this.ctx = null
      return
    }
    const stale = !this.canvas || !this.canvas.isConnected || this.canvas !== c
    if (stale) {
      this.canvas = c
      this.ctx = c.getContext("2d")
    }
  },

  trackPointer(e) {
    this.syncCanvasToDom()
    const c = this.canvas || this.el.querySelector("#game-canvas")
    if (!c) return
    const r = c.getBoundingClientRect()
    if (r.width <= 0 || r.height <= 0) return
    let x = e.clientX - r.left
    let y = e.clientY - r.top
    x = Math.max(0, Math.min(r.width, x))
    y = Math.max(0, Math.min(r.height, y))
    this.pending.cx = (x / r.width) * GW
    this.pending.cy = (y / r.height) * GH
  },

  draw(p) {
    this.syncCanvasToDom()
    if (!this.ctx || !p || !p.player) return

    const ctx = this.ctx
    ctx.fillStyle = "#0c0c14"
    ctx.fillRect(0, 0, GW, GH)

    const drawBox = (o, fill) => {
      ctx.fillStyle = fill
      const l = o.x - o.w / 2
      const t = o.y - o.h / 2
      ctx.fillRect(l, t, o.w, o.h)
    }

    if (typeof p.difficulty_tier === "number") {
      ctx.fillStyle = "#94a3b8"
      ctx.font = "12px monospace"
      ctx.fillText(`Tier ${p.difficulty_tier} · t=${p.play_tick ?? p.tick}`, 8, 16)
    }

    if (p.player_effects) {
      const active = Object.entries(p.player_effects)
        .filter(([, on]) => on)
        .map(([name]) => name)
      if (active.length > 0) {
        ctx.fillStyle = "#34d399"
        ctx.font = "12px monospace"
        ctx.fillText(active.join(" · "), 8, 32)
      }
    }

    const powerupColors = { rapid_fire: "#fb923c", multi_shot: "#38bdf8", shield: "#34d399" }
    ;(p.powerups || []).forEach((pu) => drawBox(pu, powerupColors[pu.kind] || "#facc15"))

    if (p.player_invulnerable) {
      // Blink: alternate visibility by tick parity so the flicker is tied to sim time, not wall clock.
      ctx.globalAlpha = (p.play_tick ?? p.tick) % 6 < 3 ? 1 : 0.25
      drawBox(p.player, "#38bdf8")
      ctx.globalAlpha = 1
    } else {
      drawBox(p.player, "#38bdf8")
    }
    ;(p.player_bullets || []).forEach((b) => drawBox(b, "#fbbf24"))
    ;(p.enemy_bullets || []).forEach((b) => drawBox(b, "#f87171"))
    ;(p.enemies || []).forEach((e) => drawBox(e, "#a78bfa"))
  },

  onPhase(p) {
    if (p.phase === "game_over" && typeof p.score === "number") {
      const prev = readHighScore()
      if (p.score > prev) {
        localStorage.setItem(STORAGE_KEY, String(p.score))
      }
    }
  }
}

function readHighScore() {
  try {
    return parseInt(localStorage.getItem(STORAGE_KEY) || "0", 10) || 0
  } catch {
    return 0
  }
}
