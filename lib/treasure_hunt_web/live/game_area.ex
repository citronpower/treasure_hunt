defmodule TreasureHuntWeb.GameArea do
  use TreasureHuntWeb, :live_view

  @topic "gamearea"

  def mount(_params, session, socket) do
    TreasureHuntWeb.Endpoint.subscribe(@topic) # general channel for all players

    player = Map.get(session, "_csrf_token") # fancy name of the player
    players = %{}

    if player != nil do
      players = TreasureHunt.PlayerManager.get_players() |>
                                             Map.delete(player)
    end

    #challenges = TreasureHunt.GameManager.get_challenges(player) # DEPRECATED

    state = %{
      players: players,
      player: player,
      #challenges: challenges,
      joined: false,
      game: false
    }

    {:ok, assign(socket, state)}
  end

## OVERWRITED BY game_area.html.heex
#  def render(assigns) do
#    ~L"""
#    <h1>The light is <%= @player %>.</h1>
#    """
#  end

  def handle_event("join", value, socket) do
    IO.puts("HANDLE EVENT join")
    player = Map.get(value, "player")

    players = TreasureHunt.PlayerManager.add_player(player) |>
                                             Map.delete(player)

    state = %{
      player: player,
      players: players,
      joined: true
    }

    TreasureHuntWeb.Endpoint.broadcast_from(self(), @topic, "join", state)
    TreasureHuntWeb.Endpoint.subscribe("game_" <> player) # each player open it's own channel to accept games

    {:noreply, assign(socket, state)}
  end

  def handle_event("new_challenge", value, socket) do
    IO.puts("HANDLE EVENT new_challenge")
    player = Map.get(value, "player")
    opponent = Map.get(value, "opponent")

    game = TreasureHunt.GameManager.get_random_game()
    game.start_link(player, opponent) # TODO: solve problem that we can't have multiple instances of the same game at the same time

    channel_name = "game_" <> opponent
    TreasureHuntWeb.Endpoint.subscribe(channel_name)

    broadcast_values = %{
      game: game,
      player_one: player,
      player_two: opponent,
      channel_name: channel_name
    }
    TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "enter_challenge", broadcast_values)

    state = %{
      channel_name: channel_name,
      game: inspect(game),
      game_state: :ok,
      winner: nil
    }
    {:noreply, assign(socket, state)}
  end

  def handle_event("game_answer", %{"answer" => answer, "game" => "TreasureHunt.RockPaperScissorsManager", "player" => player, "channel_name" => channel_name, "value" => _}, socket) do
    IO.puts("HANDLE EVENT game_answer")
    {res, winner} = TreasureHunt.RockPaperScissorsManager.update_answer(player, answer)

    if res != :wait do
      broadcast_values = %{
        game_state: res,
        winner: winner
      }
      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", broadcast_values)
    end

    state = %{
      game_state: res,
      winner: winner
    }
    {:noreply, assign(socket, state)}
  end

  def handle_info(%{topic: "gamearea", event: "join", payload: payload}, socket) do
    IO.puts("HANDLE INFO join: #{inspect(payload)}")

    {:noreply, assign(socket, :players, TreasureHunt.PlayerManager.get_players())}
  end

  def handle_info(%{topic: "game_" <> opponent, event: "enter_challenge", payload: payload}, socket) do
    IO.puts("HANDLE INFO enter_challenge: #{inspect(payload)}")

    state = %{
      game: inspect(Map.get(payload, :game)),
      game_state: :ok,
      winner: nil,
      channel_name: Map.get(payload, :channel_name)
    }
    {:noreply, assign(socket, state)}
  end

  def handle_info(%{topic: "game_" <> opponent, event: "game_answer", payload: payload}, socket) do
    IO.puts("HANDLE INFO game_answer: #{inspect(payload)}")

    {:noreply, assign(socket, payload)}
  end

  def handle_info(msg, socket) do
    IO.puts("HANDLE INFO other: #{inspect(msg)}")

    {:noreply, socket}
  end
end