defmodule Shmup.Game.Powerups do
  @moduledoc false

  @drop_chance_pct 12
  @max_falling_powerups 4
  @fall_speed 2.4

  @rapid_fire_duration_ticks 300
  @rapid_fire_cooldown_ticks 5

  @multi_shot_duration_ticks 300
  @multi_shot_bullet_count 3

  @shield_duration_ticks 400

  @doc "Percent chance (0-100) that a killed enemy drops a powerup."
  def drop_chance_pct, do: @drop_chance_pct

  @doc "Maximum number of powerups allowed to be falling on screen at once."
  def max_falling_powerups, do: @max_falling_powerups

  @doc "Downward velocity for falling powerups."
  def fall_speed, do: @fall_speed

  @doc "Ticks a :rapid_fire pickup remains active (assigned/refreshed, not accumulated)."
  def rapid_fire_duration_ticks, do: @rapid_fire_duration_ticks

  @doc "Player fire cooldown (ticks) while :rapid_fire is active."
  def rapid_fire_cooldown_ticks, do: @rapid_fire_cooldown_ticks

  @doc "Ticks a :multi_shot pickup remains active (assigned/refreshed, not accumulated)."
  def multi_shot_duration_ticks, do: @multi_shot_duration_ticks

  @doc "Number of bullets fired per shot while :multi_shot is active."
  def multi_shot_bullet_count, do: @multi_shot_bullet_count

  @doc "Ticks a :shield pickup remains active if it absorbs no hit."
  def shield_duration_ticks, do: @shield_duration_ticks
end
