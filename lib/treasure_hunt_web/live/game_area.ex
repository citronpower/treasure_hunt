defmodule TreasureHuntWeb.GameArea do
  use TreasureHuntWeb, :live_view
  #use Phoenix.LiveView

  @topic "gamearea"

  def mount(_params, session, socket) do
    TreasureHuntWeb.Endpoint.subscribe(@topic)

    player = Map.get(session, "_csrf_token")
    players = %{}

    if player != nil do
      players = TreasureHunt.PlayerManager.get_players() |>
                                             Map.delete(player)
    end

    challenges = TreasureHunt.GameManager.get_challenges(player)

    state = %{
      players: players,
      player: player,
      challenges: challenges,
      joined: false,
      game: false
    }

    {:ok, assign(socket, state)}
  end

## OVERWRITED BY light_live.html.heex
#  def render(assigns) do
#    ~L"""
#    <h1>The light is <%= @player %>.</h1>
#    """
#  end

  def handle_event("join", value, socket) do
    player = Map.get(value, "player")

    players = TreasureHunt.PlayerManager.add_player(player) |>
                                             Map.delete(player)
#    IO.puts("TEST")
#    IO.puts(inspect(players))
    state = %{
      player: player,
      players: players,
      joined: true
    }

    TreasureHuntWeb.Endpoint.broadcast_from(self(), @topic, "join", state)
    TreasureHuntWeb.Endpoint.subscribe("game_" <> player)

    {:noreply, assign(socket, state)}
  end

  def handle_event("new_challenge", value, socket) do
    player = Map.get(value, "player")
    opponent = Map.get(value, "opponent")

    game = TreasureHunt.GameManager.get_random_game()
    #{:ok, _pid} = TreasureHunt.GameManager.start_game(game, player, opponent)
    game.start_link(player, opponent) # problem that we can't have multiple instances of the same game at the same time

    #TreasureHunt.GameManager.add_challenge(game, player, opponent)
    channel_name = "game_" <> opponent
    TreasureHuntWeb.Endpoint.subscribe(channel_name)
    TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "enter_challenge", %{game: game, player_one: player, player_two: opponent, channel_name: channel_name})

    #{:noreply, assign(socket, %{challanges: TreasureHunt.GameManager.get_challenges(player)})}
    state = %{
      channel_name: channel_name,
      game: inspect(game),
      game_state: :ok,
      winner: nil
    }
    {:noreply, assign(socket, state)}
  end

  def handle_event("game_answer", %{"answer" => answer, "game" => "TreasureHunt.RockPaperScissorsManager", "player" => player, "channel_name" => channel_name, "value" => _}, socket) do
    IO.puts("GAME_ANSWER")
    {res, winner} = TreasureHunt.RockPaperScissorsManager.update_answer(player, answer)

    IO.puts(inspect(res))
    if res != :wait do
      IO.puts("Do I broadcast?")
      IO.puts(channel_name)
      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", %{game_state: res, winner: winner})
    end

    state = %{
      game_state: res,
      winner: winner
    }
    {:noreply, assign(socket, state)}
  end

  def handle_info(%{topic: "gamearea", event: "join", payload: payload}, socket) do
    IO.puts("HANDLE JOIN: #{inspect(payload)}")

    {:noreply, assign(socket, :players, TreasureHunt.PlayerManager.get_players())}
  end

  def handle_info(%{topic: "game_" <> opponent, event: "enter_challenge", payload: payload}, socket) do
    IO.puts("HANDLE CHALLENGE: #{inspect(payload)}")

    state = %{
      game: inspect(Map.get(payload, :game)),
      game_state: :ok,
      winner: nil,
      channel_name: Map.get(payload, :channel_name)
    }
    {:noreply, assign(socket, state)}
  end

  def handle_info(%{topic: "game_" <> opponent, event: "game_answer", payload: payload}, socket) do
    IO.puts("HANDLE ANSWER: #{inspect(payload)}")

    {:noreply, assign(socket, payload)}
  end

  def handle_info(msg, socket) do
    IO.puts("HANDLE OTHER: #{inspect(msg)}")

    {:noreply, socket}
  end
end