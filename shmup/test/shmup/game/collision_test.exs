defmodule Shmup.Game.CollisionTest do
  use ExUnit.Case, async: true

  alias Shmup.Game.Collision

  test "aabb_overlap? detects intersection" do
    a = %{x: 10, y: 10, w: 10, h: 10}
    b = %{x: 12, y: 12, w: 10, h: 10}
    assert Collision.aabb_overlap?(a, b)
  end

  test "aabb_overlap? false when separated" do
    a = %{x: 10, y: 10, w: 10, h: 10}
    b = %{x: 100, y: 100, w: 10, h: 10}
    refute Collision.aabb_overlap?(a, b)
  end

  test "resolve_player_bullets_vs_enemies removes pair and adds score" do
    b = %{x: 50, y: 50, w: 4, h: 10}
    e = %{x: 50, y: 50, w: 32, h: 28, hp: 1, id: 1}
    {bs, ens, pts, killed} = Collision.resolve_player_bullets_vs_enemies([b], [e], 10)
    assert bs == []
    assert ens == []
    assert pts == 10
    assert killed == [e]
  end

  test "resolve_player_bullets_vs_enemies decrements hp before kill" do
    b1 = %{x: 50, y: 50, w: 4, h: 10}
    b2 = %{x: 50, y: 50, w: 4, h: 10}
    e = %{x: 50, y: 50, w: 32, h: 28, hp: 2, id: 1}
    {bs, ens, pts, killed} = Collision.resolve_player_bullets_vs_enemies([b1], [e], 10)
    assert bs == []
    assert length(ens) == 1
    assert hd(ens).hp == 1
    assert pts == 0
    assert killed == []

    {bs2, ens2, pts2, killed2} = Collision.resolve_player_bullets_vs_enemies([b2], ens, 10)
    assert bs2 == []
    assert ens2 == []
    assert pts2 == 10
    assert length(killed2) == 1
  end

  test "resolve_player_vs_powerups picks up overlapping powerup and keeps the rest" do
    player = %{x: 50, y: 50, w: 36, h: 20}
    hit = %{id: 1, x: 50, y: 50, w: 20, h: 20, kind: :shield}
    miss = %{id: 2, x: 400, y: 400, w: 20, h: 20, kind: :rapid_fire}

    {kept, picked} = Collision.resolve_player_vs_powerups([hit, miss], player)
    assert kept == [miss]
    assert picked == [:shield]
  end

  test "absorb_shield_hit consumes exactly one bullet and reports absorption" do
    player = %{x: 50, y: 50, w: 36, h: 20, shield: true}
    b1 = %{x: 50, y: 50, w: 4, h: 10}
    b2 = %{x: 400, y: 400, w: 4, h: 10}

    {kept, absorbed?} = Collision.absorb_shield_hit([b1, b2], player)
    assert kept == [b2]
    assert absorbed?
  end

  test "absorb_shield_hit is a no-op without an active shield" do
    player = %{x: 50, y: 50, w: 36, h: 20, shield: false}
    b1 = %{x: 50, y: 50, w: 4, h: 10}

    {kept, absorbed?} = Collision.absorb_shield_hit([b1], player)
    assert kept == [b1]
    refute absorbed?
  end
end
