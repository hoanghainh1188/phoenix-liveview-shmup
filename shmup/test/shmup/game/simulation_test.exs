defmodule Shmup.Game.SimulationTest do
  use ExUnit.Case, async: true

  alias Shmup.Game.{GameState, Powerups, Simulation}

  defp static_enemy(id, hp) do
    %{id: id, x: 100.0, y: 100.0, w: 32, h: 28, vy: 0.0, vx: 0.0, movement: :straight, hp: hp}
  end

  defp static_bullet do
    %{x: 100.0, y: 100.0, w: 4, h: 10, vy: 0.0}
  end

  test "new_playing/0 never inherits powerup state from a previous round" do
    state = GameState.new_playing()

    assert state.powerups == []
    assert state.next_powerup_id == 1
    assert state.player.active_effects == %{}
    assert state.player.shield == false
    assert state.player.shield_expires_at == nil
  end

  test "killing an enemy below the drop threshold spawns the deterministic powerup kind" do
    state =
      struct!(GameState.new_playing(),
        enemies: [static_enemy(5, 1)],
        player_bullets: [static_bullet()],
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert new_state.enemies == []
    assert [powerup] = new_state.powerups
    assert powerup.kind == :shield
    assert_in_delta powerup.x, 100.0, 0.001
  end

  test "killing an enemy above the drop threshold spawns nothing" do
    state =
      struct!(GameState.new_playing(),
        enemies: [static_enemy(1, 1)],
        player_bullets: [static_bullet()],
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert new_state.enemies == []
    assert new_state.powerups == []
  end

  test "falling powerups are capped and do not exceed max_falling_powerups" do
    filler =
      for n <- 1..Powerups.max_falling_powerups() do
        %{id: 100 + n, x: 10.0, y: 10.0, w: 20, h: 20, vy: 0.0, kind: :shield}
      end

    state =
      struct!(GameState.new_playing(),
        powerups: filler,
        enemies: [static_enemy(5, 1)],
        player_bullets: [static_bullet()],
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert length(new_state.powerups) == Powerups.max_falling_powerups()
  end

  test "player picks up rapid_fire and the effect expiry is play_tick + duration" do
    base = GameState.new_playing()

    powerup = %{
      id: 1,
      x: base.player.x,
      y: base.player.y,
      w: 20,
      h: 20,
      vy: 0.0,
      kind: :rapid_fire
    }

    state = struct!(base, powerups: [powerup], enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert new_state.powerups == []
    assert new_state.play_tick == 1

    assert new_state.player.active_effects[:rapid_fire] ==
             1 + Powerups.rapid_fire_duration_ticks()
  end

  test "player picks up shield and it activates with an expiry" do
    base = GameState.new_playing()
    powerup = %{id: 1, x: base.player.x, y: base.player.y, w: 20, h: 20, vy: 0.0, kind: :shield}
    state = struct!(base, powerups: [powerup], enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert new_state.player.shield == true
    assert new_state.player.shield_expires_at == 1 + Powerups.shield_duration_ticks()
  end

  test "picking up the same effect kind again refreshes rather than stacks the expiry" do
    base = GameState.new_playing()
    player = %{base.player | active_effects: %{rapid_fire: 260}}

    powerup = %{id: 1, x: player.x, y: player.y, w: 20, h: 20, vy: 0.0, kind: :rapid_fire}

    state =
      struct!(base, play_tick: 250, player: player, powerups: [powerup], enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert new_state.play_tick == 251

    assert new_state.player.active_effects[:rapid_fire] ==
             251 + Powerups.rapid_fire_duration_ticks()
  end

  test "an expired effect is cleared instead of lingering" do
    base = GameState.new_playing()
    player = %{base.player | active_effects: %{rapid_fire: 5}}
    state = struct!(base, play_tick: 10, player: player, enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert new_state.play_tick == 11
    assert new_state.player.active_effects == %{}
  end

  test "rapid_fire and multi_shot combine: faster cooldown, multiple bullets" do
    base = GameState.new_playing()

    player = %{
      base.player
      | active_effects: %{rapid_fire: 100_000, multi_shot: 100_000}
    }

    state =
      struct!(base,
        player: player,
        pending_input: %{cx: player.x, cy: player.y, primary: true},
        player_fire_cd: 0,
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert length(new_state.player_bullets) == Powerups.multi_shot_bullet_count()
    assert new_state.player_fire_cd == Powerups.rapid_fire_cooldown_ticks()
    assert Enum.map(new_state.player_bullets, & &1.vx) |> Enum.sort() == [-2.5, 0.0, 2.5]
  end

  test "an active shield absorbs exactly one enemy bullet and survives the tick" do
    base = GameState.new_playing()
    player = %{base.player | shield: true, shield_expires_at: 100_000}
    bullet = %{x: player.x, y: player.y, w: 4, h: 10, vy: 0.0}

    state =
      struct!(base,
        player: player,
        enemy_bullets: [bullet],
        pending_input: %{cx: player.x, cy: player.y, primary: false},
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert new_state.phase == :playing
    assert new_state.player.shield == false
    assert new_state.player.shield_expires_at == nil
    assert new_state.enemy_bullets == []
  end

  test "without a shield, an enemy bullet still ends the game as before" do
    base = GameState.new_playing()
    bullet = %{x: base.player.x, y: base.player.y, w: 4, h: 10, vy: 0.0}

    state =
      struct!(base,
        enemy_bullets: [bullet],
        pending_input: %{cx: base.player.x, cy: base.player.y, primary: false},
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert new_state.phase == :game_over
  end

  test "falling powerups are culled once they pass the bottom of the playfield" do
    base = GameState.new_playing()
    offscreen = %{id: 9, x: 10.0, y: base.height + 81.0, w: 20, h: 20, vy: 2.4, kind: :shield}
    state = struct!(base, powerups: [offscreen], enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert new_state.powerups == []
  end
end
