defmodule Shmup.Game.Health do
  @moduledoc false

  @max_hp 3
  @invulnerability_duration_ticks 60

  @doc "Player's starting and maximum hit points."
  def max_hp, do: @max_hp

  @doc "Ticks the player stays invulnerable after losing a hit point (~3s @ 20Hz)."
  def invulnerability_duration_ticks, do: @invulnerability_duration_ticks
end
