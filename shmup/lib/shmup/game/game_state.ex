defmodule Shmup.Game.GameState do
  @moduledoc false

  alias Shmup.Game.{Enemies, Health}

  @type phase :: :splash | :playing | :game_over

  @enforce_keys [:phase, :score, :tick, :width, :height]
  defstruct [
    :phase,
    :score,
    :tick,
    :width,
    :height,
    player: nil,
    player_bullets: [],
    enemy_bullets: [],
    enemies: [],
    powerups: [],
    next_id: 1,
    next_powerup_id: 1,
    player_fire_cd: 0,
    enemy_spawn_cd: 0,
    enemy_fire_cd: 0,
    pending_input: %{cx: 0.0, cy: 0.0, primary: false},
    difficulty_tier: 0,
    play_tick: 0,
    next_boss_tier: 1,
    kill_events: []
  ]

  @doc "Logical playfield size in game units (matches hook canvas coordinate system)."
  def default_width, do: 480
  def default_height, do: 640

  def new_splash do
    %__MODULE__{
      phase: :splash,
      score: 0,
      tick: 0,
      width: default_width(),
      height: default_height()
    }
  end

  def new_playing do
    w = default_width()
    h = default_height()

    %__MODULE__{
      phase: :playing,
      score: 0,
      tick: 0,
      width: w,
      height: h,
      player: %{
        x: w / 2,
        y: h - 60,
        w: 36,
        h: 20,
        hp: Health.max_hp(),
        max_hp: Health.max_hp(),
        invulnerable_until: nil,
        active_effects: %{},
        shield: false,
        shield_expires_at: nil
      },
      player_bullets: [],
      enemy_bullets: [],
      enemies: [],
      powerups: [],
      next_id: 1,
      next_powerup_id: 1,
      player_fire_cd: 0,
      enemy_spawn_cd: 30,
      enemy_fire_cd: 0,
      pending_input: %{cx: w / 2, cy: h - 60, primary: false},
      difficulty_tier: 0,
      play_tick: 0,
      next_boss_tier: Enemies.boss_tier_interval(),
      kill_events: []
    }
  end

  def new_game_over(%__MODULE__{} = st) do
    %{st | phase: :game_over}
  end
end
