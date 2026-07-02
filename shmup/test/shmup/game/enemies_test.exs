defmodule Shmup.Game.EnemiesTest do
  use ExUnit.Case, async: true

  alias Shmup.Game.Enemies

  test "exposes finite, positive tuning parameters" do
    assert Enemies.tank_min_tier() >= 0
    assert Enemies.tank_chance_pct() > 0
    assert Enemies.tank_chance_pct() < 100
    assert Enemies.tank_hp_multiplier() > 1
    assert Enemies.tank_speed_multiplier() > 0
    assert Enemies.tank_speed_multiplier() < 1
    assert Enemies.tank_size_multiplier() > 1
    assert Enemies.boss_tier_interval() > 0
    assert Enemies.boss_hp_multiplier() > 1
    assert Enemies.boss_bonus_points() > 0
    assert Enemies.boss_width() > 32
    assert Enemies.boss_height() > 28
  end

  test "pick_kind/2 always returns :grunt below tank_min_tier regardless of id" do
    for id <- 1..20 do
      assert Enemies.pick_kind(0, id) == :grunt
    end
  end

  test "pick_kind/2 is deterministic for the same tier and id" do
    assert Enemies.pick_kind(2, 3) == Enemies.pick_kind(2, 3)
    assert Enemies.pick_kind(2, 1) == :grunt
    assert Enemies.pick_kind(2, 3) == :tank
  end
end
