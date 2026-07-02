defmodule Shmup.Game.HealthTest do
  use ExUnit.Case, async: true

  alias Shmup.Game.Health

  test "exposes finite, positive tuning parameters" do
    assert Health.max_hp() > 1
    assert Health.invulnerability_duration_ticks() > 0
  end
end
