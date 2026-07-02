defmodule ShmupWeb.GameLive do
  use ShmupWeb, :live_view

  alias Shmup.Game.{GameState, Simulation}

  @tick_ms 50

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Shmup")
     |> assign(:game, GameState.new_splash())
     |> assign(:high_score_display, 0)}
  end

  @impl true
  def handle_event("start", _params, socket) do
    game = GameState.new_playing()

    socket =
      socket
      |> assign(:game, game)
      |> push_event("frame", snapshot(game))

    {:noreply, schedule_tick(socket)}
  end

  def handle_event("to_splash", _params, socket) do
    {:noreply, assign(socket, :game, GameState.new_splash())}
  end

  def handle_event("client_high_score", %{"value" => v}, socket) do
    v = parse_int(v)
    {:noreply, assign(socket, :high_score_display, v)}
  end

  def handle_event("input", params, socket) do
    g = socket.assigns.game

    if g.phase == :playing do
      cx = to_float(params["cx"])
      cy = to_float(params["cy"])
      pr = truthy?(params["primary"])
      g2 = %{g | pending_input: %{cx: cx, cy: cy, primary: pr}}
      {:noreply, assign(socket, :game, g2)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:tick, socket) do
    g = socket.assigns.game

    if g.phase != :playing do
      {:noreply, socket}
    else
      g2 = Simulation.step(g)
      socket = assign(socket, :game, g2)

      cond do
        g2.phase == :playing ->
          socket = push_event(socket, "frame", snapshot(g2))
          {:noreply, schedule_tick(socket)}

        g2.phase == :game_over ->
          socket =
            socket
            |> push_event("phase", %{phase: "game_over", score: g2.score})
            |> push_event("frame", snapshot(g2))

          {:noreply, socket}

        true ->
          {:noreply, socket}
      end
    end
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, @tick_ms)
    socket
  end

  # Jason cannot encode enemy :movement tuples — only send drawable fields to the hook.
  @enemy_snapshot_keys [:x, :y, :w, :h, :id, :hp, :kind]
  @powerup_snapshot_keys [:id, :x, :y, :w, :h, :kind]

  defp snapshot(%GameState{phase: :playing} = g) do
    %{
      tick: g.tick,
      score: g.score,
      width: g.width,
      height: g.height,
      difficulty_tier: g.difficulty_tier,
      play_tick: g.play_tick,
      player: g.player,
      player_bullets: g.player_bullets,
      enemy_bullets: g.enemy_bullets,
      enemies: Enum.map(g.enemies, &Map.take(&1, @enemy_snapshot_keys)),
      powerups: Enum.map(g.powerups, &Map.take(&1, @powerup_snapshot_keys)),
      player_effects: player_effects(g.player),
      player_invulnerable: invulnerable?(g.player, g.play_tick),
      kill_events: g.kill_events
    }
  end

  defp snapshot(%GameState{phase: phase} = g) do
    %{
      tick: g.tick,
      score: g.score,
      phase: to_string(phase),
      width: g.width,
      height: g.height
    }
  end

  defp player_effects(player) do
    %{
      rapid_fire: Map.has_key?(player.active_effects, :rapid_fire),
      multi_shot: Map.has_key?(player.active_effects, :multi_shot),
      shield: player.shield
    }
  end

  defp invulnerable?(%{invulnerable_until: nil}, _play_tick), do: false
  defp invulnerable?(%{invulnerable_until: until_tick}, play_tick), do: until_tick > play_tick

  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v * 1.0

  defp to_float(v) do
    {f, _} = Float.parse(to_string(v))
    f
  end

  defp truthy?(v) when v in [true, "true", 1, "1"], do: true
  defp truthy?(_), do: false

  defp parse_int(v) when is_integer(v), do: v

  defp parse_int(v) do
    case Integer.parse(to_string(v)) do
      {i, _} -> i
      :error -> 0
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="game-root"
      class="min-h-screen bg-slate-950 text-slate-100 flex flex-col items-center justify-start pt-8"
      phx-hook="GameHook"
      data-phase={@game.phase}
      data-score={@game.score}
    >
      <%= if @game.phase == :splash do %>
        <h1 class="text-3xl font-bold mb-2">Shmup</h1>
        <p class="mb-6 text-slate-400">
          Kỷ lục: <span class="text-amber-400 font-mono">{@high_score_display}</span>
        </p>
        <button
          type="button"
          phx-click="start"
          class="px-8 py-3 rounded-lg bg-emerald-600 hover:bg-emerald-500 font-semibold"
        >
          BẮT ĐẦU
        </button>
      <% end %>

      <%= if @game.phase == :playing do %>
        <div class="text-sm text-slate-400 mb-2">
          Điểm: <span id="score-value" class="text-white font-mono inline-block">{@game.score}</span>
          · Máu: <span class="text-rose-400 font-mono">{@game.player.hp}/{@game.player.max_hp}</span>
        </div>
        <canvas
          id="game-canvas"
          width="480"
          height="640"
          class="block rounded border border-slate-700 bg-slate-900 touch-none"
        />
      <% end %>

      <%= if @game.phase == :game_over do %>
        <div class="flex flex-col items-center gap-4 p-8">
          <h2 class="text-2xl font-bold text-rose-400">Hết trận</h2>
          <p class="text-lg">Điểm: <span class="font-mono text-amber-300">{@game.score}</span></p>
          <button
            type="button"
            phx-click="to_splash"
            class="px-6 py-2 rounded-lg bg-slate-700 hover:bg-slate-600"
          >
            Về màn hình chính
          </button>
        </div>
      <% end %>
    </div>
    """
  end
end
