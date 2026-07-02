defmodule Shmup.Game.SimulationTest do
  use ExUnit.Case, async: true

  alias Shmup.Game.{Difficulty, Enemies, GameState, Health, Powerups, Simulation}

  defp static_enemy(id, hp, kind \\ :grunt) do
    %{
      id: id,
      x: 100.0,
      y: 100.0,
      w: 32,
      h: 28,
      vy: 0.0,
      vx: 0.0,
      movement: :straight,
      hp: hp,
      kind: kind
    }
  end

  defp static_bullet do
    %{x: 100.0, y: 100.0, w: 4, h: 10, vy: 0.0}
  end

  test "new_playing/0 never inherits powerup or health state from a previous round" do
    state = GameState.new_playing()

    assert state.powerups == []
    assert state.next_powerup_id == 1
    assert state.player.active_effects == %{}
    assert state.player.shield == false
    assert state.player.shield_expires_at == nil
    assert state.player.hp == Health.max_hp()
    assert state.player.max_hp == Health.max_hp()
    assert state.player.invulnerable_until == nil
    assert state.next_boss_tier == Enemies.boss_tier_interval()
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
    assert new_state.player.hp == base.player.hp
    assert new_state.player.invulnerable_until == nil
  end

  test "without a shield, an enemy bullet costs one hp instead of ending the game outright" do
    base = GameState.new_playing()
    bullet = %{x: base.player.x, y: base.player.y, w: 4, h: 10, vy: 0.0}

    state =
      struct!(base,
        enemy_bullets: [bullet],
        pending_input: %{cx: base.player.x, cy: base.player.y, primary: false},
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert new_state.phase == :playing
    assert new_state.player.hp == base.player.max_hp - 1
    assert new_state.player.invulnerable_until == 1 + Health.invulnerability_duration_ticks()
  end

  test "multiple enemy bullets overlapping in the same tick only cost one hp" do
    base = GameState.new_playing()
    b1 = %{x: base.player.x, y: base.player.y, w: 4, h: 10, vy: 0.0}
    b2 = %{x: base.player.x, y: base.player.y, w: 4, h: 10, vy: 0.0}

    state =
      struct!(base,
        enemy_bullets: [b1, b2],
        pending_input: %{cx: base.player.x, cy: base.player.y, primary: false},
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert new_state.player.hp == base.player.max_hp - 1
  end

  test "invulnerability blocks further hp loss until it expires" do
    base = GameState.new_playing()
    player = %{base.player | hp: 2, invulnerable_until: 50}
    bullet = %{x: player.x, y: player.y, w: 4, h: 10, vy: 0.0}

    still_invulnerable =
      struct!(base,
        play_tick: 40,
        player: player,
        enemy_bullets: [bullet],
        pending_input: %{cx: player.x, cy: player.y, primary: false},
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(still_invulnerable)

    assert new_state.play_tick == 41
    assert new_state.player.hp == 2
    assert new_state.player.invulnerable_until == 50

    expired =
      struct!(base,
        play_tick: 50,
        player: player,
        enemy_bullets: [bullet],
        pending_input: %{cx: player.x, cy: player.y, primary: false},
        enemy_spawn_cd: 999
      )

    new_state2 = Simulation.step(expired)

    assert new_state2.play_tick == 51
    assert new_state2.player.hp == 1
    assert new_state2.player.invulnerable_until == 51 + Health.invulnerability_duration_ticks()
  end

  test "the game only ends once hp reaches zero" do
    base = GameState.new_playing()
    player = %{base.player | hp: 1, invulnerable_until: nil}
    bullet = %{x: player.x, y: player.y, w: 4, h: 10, vy: 0.0}

    state =
      struct!(base,
        player: player,
        enemy_bullets: [bullet],
        pending_input: %{cx: player.x, cy: player.y, primary: false},
        enemy_spawn_cd: 999
      )

    new_state = Simulation.step(state)

    assert new_state.player.hp == 0
    assert new_state.phase == :game_over
  end

  test "shield absorption then a later unshielded hit both behave correctly in sequence" do
    base = GameState.new_playing()
    shielded_player = %{base.player | shield: true, shield_expires_at: 100_000}
    bullet = %{x: shielded_player.x, y: shielded_player.y, w: 4, h: 10, vy: 0.0}

    shielded_state =
      struct!(base,
        player: shielded_player,
        enemy_bullets: [bullet],
        pending_input: %{cx: shielded_player.x, cy: shielded_player.y, primary: false},
        enemy_spawn_cd: 999
      )

    after_shield = Simulation.step(shielded_state)

    assert after_shield.player.hp == base.player.max_hp
    assert after_shield.player.invulnerable_until == nil
    assert after_shield.player.shield == false

    bullet2 = %{x: after_shield.player.x, y: after_shield.player.y, w: 4, h: 10, vy: 0.0}

    unshielded_state =
      struct!(after_shield,
        enemy_bullets: [bullet2],
        pending_input: %{cx: after_shield.player.x, cy: after_shield.player.y, primary: false}
      )

    after_hit = Simulation.step(unshielded_state)

    assert after_hit.player.hp == base.player.max_hp - 1
    assert after_hit.player.invulnerable_until != nil
  end

  test "falling powerups are culled once they pass the bottom of the playfield" do
    base = GameState.new_playing()
    offscreen = %{id: 9, x: 10.0, y: base.height + 81.0, w: 20, h: 20, vy: 2.4, kind: :shield}
    state = struct!(base, powerups: [offscreen], enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert new_state.powerups == []
  end

  test "spawning at a tank-selected id produces a slower, tougher, larger enemy than a grunt" do
    base = GameState.new_playing()

    tank_state =
      struct!(base, difficulty_tier: 2, next_id: 3, enemy_spawn_cd: 0)

    tank_result = Simulation.step(tank_state)
    assert [tank] = tank_result.enemies
    assert tank.kind == :tank
    assert tank.hp == round(Difficulty.enemy_hp(2) * Enemies.tank_hp_multiplier())
    assert_in_delta tank.vy, 1.8 * Enemies.tank_speed_multiplier(), 0.001
    assert tank.w == round(32 * Enemies.tank_size_multiplier())

    grunt_state =
      struct!(base, difficulty_tier: 2, next_id: 1, enemy_spawn_cd: 0)

    grunt_result = Simulation.step(grunt_state)
    assert [grunt] = grunt_result.enemies
    assert grunt.kind == :grunt
    assert grunt.hp == Difficulty.enemy_hp(2)
    assert_in_delta grunt.vy, 1.8, 0.001
    assert grunt.w == 32

    assert tank.hp > grunt.hp
    assert tank.vy < grunt.vy
    assert tank.w > grunt.w
  end

  test "below tank_min_tier every spawn is a grunt regardless of id" do
    base = GameState.new_playing()
    state = struct!(base, difficulty_tier: 0, next_id: 3, enemy_spawn_cd: 0)

    new_state = Simulation.step(state)

    assert [enemy] = new_state.enemies
    assert enemy.kind == :grunt
  end

  test "a boss spawns exactly once when difficulty_tier reaches next_boss_tier" do
    base = GameState.new_playing()
    assert base.next_boss_tier == Enemies.boss_tier_interval()

    state = struct!(base, difficulty_tier: Enemies.boss_tier_interval(), enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert [boss] = new_state.enemies
    assert boss.kind == :boss

    assert boss.hp ==
             round(
               Difficulty.enemy_hp(Enemies.boss_tier_interval()) * Enemies.boss_hp_multiplier()
             )

    assert new_state.next_boss_tier == Enemies.boss_tier_interval() * 2

    # tier hasn't moved past the same milestone yet — stepping again must not spawn a second boss
    no_double_spawn = Simulation.step(new_state)
    assert length(no_double_spawn.enemies) == 1
  end

  test "killing a boss awards a large bonus on top of the base kill score" do
    base = GameState.new_playing()
    boss = static_enemy(1, 1, :boss)
    bullet = static_bullet()

    state =
      struct!(base, enemies: [boss], player_bullets: [bullet], enemy_spawn_cd: 999)

    new_state = Simulation.step(state)

    assert new_state.enemies == []
    assert new_state.score == 10 + Enemies.boss_bonus_points()
  end
end
