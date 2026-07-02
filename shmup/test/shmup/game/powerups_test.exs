defmodule Shmup.Game.PowerupsTest do
  use ExUnit.Case, async: true

  alias Shmup.Game.Powerups

  test "exposes finite, positive tuning parameters" do
    assert Powerups.drop_chance_pct() > 0
    assert Powerups.drop_chance_pct() < 100
    assert Powerups.max_falling_powerups() > 0
    assert Powerups.fall_speed() > 0
    assert Powerups.rapid_fire_duration_ticks() > 0
    assert Powerups.rapid_fire_cooldown_ticks() > 0
    assert Powerups.multi_shot_duration_ticks() > 0
    assert Powerups.multi_shot_bullet_count() > 1
    assert Powerups.shield_duration_ticks() > 0
  end
end
