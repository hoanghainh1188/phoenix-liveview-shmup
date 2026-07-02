defmodule Shmup.Game.Simulation do
  @moduledoc false

  alias Shmup.Game.{Collision, Difficulty, Enemies, GameState, Health, Physics, Powerups}

  @player_fire_cooldown 10
  @points_per_kill 10
  @powerup_kinds [:rapid_fire, :multi_shot, :shield]
  @powerup_size 20
  @multi_shot_vx_offsets [-2.5, 0.0, 2.5]
  @drop_hash_multiplier 2_654_435_761

  def step(%GameState{phase: p} = s) when p != :playing, do: s

  def step(%GameState{} = s) do
    s
    |> Map.update!(:tick, &(&1 + 1))
    |> advance_play_time()
    |> maybe_spawn_boss()
    |> apply_input()
    |> tick_cooldowns()
    |> tick_effects()
    |> maybe_spawn_enemy()
    |> fire_player_bullet()
    |> move_all()
    |> enemy_fire()
    |> resolve_hits()
    |> resolve_powerup_pickup()
    |> cull_offscreen()
    |> absorb_shield()
    |> apply_damage()
    |> check_player_death()
  end

  defp advance_play_time(%GameState{} = s) do
    play_tick = s.play_tick + 1
    tier = s.difficulty_tier

    tier =
      if play_tick > 0 && rem(play_tick, Difficulty.tier_period_ticks()) == 0 do
        min(tier + 1, Difficulty.tier_max())
      else
        tier
      end

    %{s | play_tick: play_tick, difficulty_tier: tier}
  end

  defp apply_input(%GameState{} = s) do
    %{cx: cx, cy: cy, primary: _} = s.pending_input
    %{w: pw, h: ph} = s.player
    {nx, ny} = Physics.clamp_player_center(cx, cy, s.width, s.height, pw, ph)
    %{s | player: %{s.player | x: nx, y: ny}}
  end

  defp tick_cooldowns(s) do
    pcd = max(0, s.player_fire_cd - 1)
    esc = max(0, s.enemy_spawn_cd - 1)
    %{s | player_fire_cd: pcd, enemy_spawn_cd: esc}
  end

  defp tick_effects(%GameState{play_tick: pt, player: pl} = s) do
    active =
      pl.active_effects
      |> Enum.reject(fn {_kind, expires_at} -> expires_at <= pt end)
      |> Map.new()

    player = %{pl | active_effects: active}

    player =
      if player.shield and player.shield_expires_at <= pt do
        %{player | shield: false, shield_expires_at: nil}
      else
        player
      end

    %{s | player: player}
  end

  defp maybe_spawn_enemy(%GameState{enemy_spawn_cd: cd} = s) when cd != 0, do: s

  defp maybe_spawn_enemy(%GameState{} = s) do
    max_e = Difficulty.max_enemies(s.difficulty_tier)

    if length(s.enemies) >= max_e do
      interval = Difficulty.spawn_interval(s.difficulty_tier)
      %{s | enemy_spawn_cd: interval}
    else
      spawn_one_enemy(s)
    end
  end

  defp spawn_one_enemy(%GameState{} = s) do
    margin = 40
    x = margin + rem(s.tick * 7919, max(1, trunc(s.width) - 2 * margin))
    tier = s.difficulty_tier
    id = s.next_id
    mov = movement_for_tier(tier, id)
    kind = Enemies.pick_kind(tier, id)
    enemy = build_enemy(kind, id, x * 1.0, mov, tier)

    interval = Difficulty.spawn_interval(tier)

    %{
      s
      | enemies: [enemy | s.enemies],
        enemy_spawn_cd: interval,
        next_id: id + 1
    }
  end

  defp build_enemy(:grunt, id, x, mov, tier) do
    %{
      id: id,
      x: x,
      y: 30.0,
      w: 32,
      h: 28,
      vy: 1.8,
      vx: 0.0,
      movement: mov,
      hp: Difficulty.enemy_hp(tier),
      kind: :grunt
    }
  end

  defp build_enemy(:tank, id, x, mov, tier) do
    base_hp = Difficulty.enemy_hp(tier)

    %{
      id: id,
      x: x,
      y: 30.0,
      w: round(32 * Enemies.tank_size_multiplier()),
      h: round(28 * Enemies.tank_size_multiplier()),
      vy: 1.8 * Enemies.tank_speed_multiplier(),
      vx: 0.0,
      movement: mov,
      hp: round(base_hp * Enemies.tank_hp_multiplier()),
      kind: :tank
    }
  end

  defp maybe_spawn_boss(%GameState{difficulty_tier: tier, next_boss_tier: nbt} = s)
       when tier < nbt,
       do: s

  defp maybe_spawn_boss(%GameState{} = s) do
    tier = s.difficulty_tier
    id = s.next_id
    mov = movement_for_tier(tier, id)
    base_hp = Difficulty.enemy_hp(tier)

    boss = %{
      id: id,
      x: s.width / 2,
      y: 30.0,
      w: Enemies.boss_width(),
      h: Enemies.boss_height(),
      vy: 1.8 * Enemies.tank_speed_multiplier(),
      vx: 0.0,
      movement: mov,
      hp: round(base_hp * Enemies.boss_hp_multiplier()),
      kind: :boss
    }

    %{
      s
      | enemies: [boss | s.enemies],
        next_id: id + 1,
        next_boss_tier: s.next_boss_tier + Enemies.boss_tier_interval()
    }
  end

  defp movement_for_tier(tier, id) do
    t = min(tier, Difficulty.tier_max())
    phase0 = id * 0.73

    cond do
      t <= 1 ->
        :straight

      t <= 4 ->
        {:sine, phase0, 2.2 + t * 0.35, 0.085}

      true ->
        {:composite, phase0, 3.5 + min(t, 10) * 0.25, 0.11, 1.2 + t * 0.05}
    end
  end

  defp fire_player_bullet(%GameState{pending_input: %{primary: false}} = s), do: s

  defp fire_player_bullet(%GameState{player_fire_cd: cd} = s) when cd > 0, do: s

  defp fire_player_bullet(%GameState{player: pl} = s) do
    cooldown =
      if Map.has_key?(pl.active_effects, :rapid_fire) do
        Powerups.rapid_fire_cooldown_ticks()
      else
        @player_fire_cooldown
      end

    new_bullets = spawn_player_bullets(pl)

    %{
      s
      | player_bullets: new_bullets ++ s.player_bullets,
        player_fire_cd: cooldown
    }
  end

  defp spawn_player_bullets(%{active_effects: effects} = pl) do
    top_y = pl.y - pl.h / 2 - 6

    if Map.has_key?(effects, :multi_shot) do
      Enum.map(@multi_shot_vx_offsets, fn vx ->
        %{x: pl.x, y: top_y, w: 4, h: 10, vy: -14.0, vx: vx}
      end)
    else
      [%{x: pl.x, y: top_y, w: 4, h: 10, vy: -14.0}]
    end
  end

  defp move_all(%GameState{} = s) do
    pbs =
      Enum.map(s.player_bullets, fn b ->
        %{b | x: b.x + Map.get(b, :vx, 0.0), y: b.y + b.vy}
      end)

    ebs =
      Enum.map(s.enemy_bullets, fn b ->
        %{b | y: b.y + b.vy}
      end)

    pt = s.play_tick

    ens =
      Enum.map(s.enemies, fn e ->
        Physics.step_enemy(e, pt)
      end)

    pus =
      Enum.map(s.powerups, fn p ->
        %{p | y: p.y + p.vy}
      end)

    %{s | player_bullets: pbs, enemy_bullets: ebs, enemies: ens, powerups: pus}
  end

  defp enemy_fire(%GameState{enemies: []} = s), do: s

  defp enemy_fire(%GameState{play_tick: pt} = s) when pt <= 0, do: s

  defp enemy_fire(%GameState{} = s) do
    period = Difficulty.enemy_fire_period(s.difficulty_tier)

    if rem(s.play_tick, period) != 0 do
      s
    else
      e = List.first(s.enemies)

      b = %{
        x: e.x,
        y: e.y + e.h / 2 + 4,
        w: 4,
        h: 10,
        vy: 9.0
      }

      %{s | enemy_bullets: [b | s.enemy_bullets]}
    end
  end

  defp resolve_hits(%GameState{} = s) do
    {pbs, ens, pts, killed} =
      Collision.resolve_player_bullets_vs_enemies(
        s.player_bullets,
        s.enemies,
        @points_per_kill
      )

    boss_bonus =
      killed
      |> Enum.count(&(&1.kind == :boss))
      |> Kernel.*(Enemies.boss_bonus_points())

    %{s | player_bullets: pbs, enemies: ens, score: s.score + pts + boss_bonus}
    |> maybe_spawn_powerups(killed)
  end

  defp maybe_spawn_powerups(s, killed_enemies) do
    Enum.reduce(killed_enemies, s, &maybe_spawn_powerup(&2, &1))
  end

  defp maybe_spawn_powerup(s, enemy) do
    roll = rem(enemy.id * @drop_hash_multiplier, 100)

    cond do
      roll >= Powerups.drop_chance_pct() ->
        s

      length(s.powerups) >= Powerups.max_falling_powerups() ->
        s

      true ->
        kind = Enum.at(@powerup_kinds, rem(enemy.id, length(@powerup_kinds)))

        powerup = %{
          id: s.next_powerup_id,
          x: enemy.x,
          y: enemy.y,
          w: @powerup_size,
          h: @powerup_size,
          vy: Powerups.fall_speed(),
          kind: kind
        }

        %{s | powerups: [powerup | s.powerups], next_powerup_id: s.next_powerup_id + 1}
    end
  end

  defp resolve_powerup_pickup(%GameState{} = s) do
    {kept, picked_kinds} = Collision.resolve_player_vs_powerups(s.powerups, s.player)
    player = Enum.reduce(picked_kinds, s.player, &apply_powerup_effect(&2, &1, s.play_tick))
    %{s | powerups: kept, player: player}
  end

  defp apply_powerup_effect(player, :rapid_fire, play_tick) do
    expires_at = play_tick + Powerups.rapid_fire_duration_ticks()
    %{player | active_effects: Map.put(player.active_effects, :rapid_fire, expires_at)}
  end

  defp apply_powerup_effect(player, :multi_shot, play_tick) do
    expires_at = play_tick + Powerups.multi_shot_duration_ticks()
    %{player | active_effects: Map.put(player.active_effects, :multi_shot, expires_at)}
  end

  defp apply_powerup_effect(player, :shield, play_tick) do
    %{player | shield: true, shield_expires_at: play_tick + Powerups.shield_duration_ticks()}
  end

  defp cull_offscreen(%GameState{width: _w, height: h} = s) do
    pbs = Enum.filter(s.player_bullets, fn b -> b.y > -30 end)
    ebs = Enum.filter(s.enemy_bullets, fn b -> b.y < h + 40 end)
    ens = Enum.filter(s.enemies, fn e -> e.y < h + 80 end)
    pus = Enum.filter(s.powerups, fn p -> p.y < h + 80 end)
    %{s | player_bullets: pbs, enemy_bullets: ebs, enemies: ens, powerups: pus}
  end

  defp absorb_shield(%GameState{} = s) do
    {ebs, absorbed?} = Collision.absorb_shield_hit(s.enemy_bullets, s.player)

    if absorbed? do
      %{s | enemy_bullets: ebs, player: %{s.player | shield: false, shield_expires_at: nil}}
    else
      s
    end
  end

  defp apply_damage(%GameState{play_tick: pt, player: pl} = s) do
    if invulnerable?(pl, pt) do
      s
    else
      if Collision.enemy_hits_player?(s.enemy_bullets, pl) do
        player = %{
          pl
          | hp: max(0, pl.hp - 1),
            invulnerable_until: pt + Health.invulnerability_duration_ticks()
        }

        %{s | player: player}
      else
        s
      end
    end
  end

  defp invulnerable?(%{invulnerable_until: nil}, _play_tick), do: false
  defp invulnerable?(%{invulnerable_until: until_tick}, play_tick), do: until_tick > play_tick

  defp check_player_death(%GameState{player: %{hp: hp}} = s) do
    if hp <= 0 do
      GameState.new_game_over(s)
    else
      s
    end
  end
end
