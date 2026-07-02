defmodule Shmup.Game.Enemies do
  @moduledoc false

  @tank_min_tier 2
  @tank_chance_pct 30
  @tank_hp_multiplier 3
  @tank_speed_multiplier 0.5
  @tank_size_multiplier 1.4

  @boss_tier_interval 5
  @boss_hp_multiplier 15
  @boss_bonus_points 240
  @boss_width 90
  @boss_height 70

  # Distinct from Powerups' hash multiplier so the two systems don't correlate
  # (the same enemy id shouldn't always "hit" or "miss" both rolls together).
  @kind_hash_multiplier 179_424_673

  def tank_min_tier, do: @tank_min_tier
  def tank_chance_pct, do: @tank_chance_pct
  def tank_hp_multiplier, do: @tank_hp_multiplier
  def tank_speed_multiplier, do: @tank_speed_multiplier
  def tank_size_multiplier, do: @tank_size_multiplier

  def boss_tier_interval, do: @boss_tier_interval
  def boss_hp_multiplier, do: @boss_hp_multiplier
  def boss_bonus_points, do: @boss_bonus_points
  def boss_width, do: @boss_width
  def boss_height, do: @boss_height

  @doc "Deterministically picks a regular enemy kind (:grunt or :tank) from tier and id."
  def pick_kind(tier, _id) when tier < @tank_min_tier, do: :grunt

  def pick_kind(_tier, id) do
    roll = rem(id * @kind_hash_multiplier, 100)
    if roll < @tank_chance_pct, do: :tank, else: :grunt
  end
end
