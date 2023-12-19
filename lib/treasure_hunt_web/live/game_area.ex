defmodule TreasureHuntWeb.GameArea do
  use TreasureHuntWeb, :live_view

  @topic "gamearea"

  # initiate
  def mount(_params, session, socket) do
    TreasureHuntWeb.Endpoint.subscribe(@topic) # general channel for all players

    player = Map.get(session, "_csrf_token") # fancy name of the player

    state = %{
      player: player,
      random_number: nil,
      revealed_digits_count: 0,
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

  # handle the click on the button "JOIN THE GAME !"
  def handle_event("join", value, socket) do
    IO.puts("HANDLE EVENT join")
    player = Map.get(value, "player")

    players = TreasureHunt.PlayerManager.add_player(player) |>
                                             Map.delete(player)

    random_number = TreasureHunt.PlayerManager.get_player_random_number(player)
    revealed_digits_count = TreasureHunt.PlayerManager.get_player_revealed_digits_count(player)

    state = %{
      player: player,
      random_number: random_number,
      revealed_digits_count: revealed_digits_count,
      players: players,
      joined: true
    }

    TreasureHuntWeb.Endpoint.broadcast_from(self(), @topic, "join", state)
    TreasureHuntWeb.Endpoint.subscribe("game_" <> player) # each player open it's own channel to accept games

    {:noreply, assign(socket, state)}
  end

  # handle the click on the button to challenge another player
  def handle_event("new_challenge", value, socket) do
    IO.puts("HANDLE EVENT new_challenge")
    player = Map.get(value, "player")
    opponent = Map.get(value, "opponent")
    revealed_digits_count = TreasureHunt.PlayerManager.get_player_revealed_digits_count(player)

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
      winner: nil,
      revealed_digits_count: revealed_digits_count
    }
    {:noreply, assign(socket, state)}
  end

 def handle_event("game_answer", %{"answer" => answer, "game" => "TreasureHunt.RockPaperScissorsManager", "player" => player, "channel_name" => channel_name, "value" => _}, socket) do
    IO.puts("HANDLE EVENT game_answer")
    {res, winner} = TreasureHunt.RockPaperScissorsManager.update_answer(player, answer)

    revealed_digits_count = TreasureHunt.PlayerManager.get_player_revealed_digits_count(player)

    IO.puts(res)
    IO.puts(winner)

    if res != :wait do

      broadcast_values = %{
        game_state: res,
        winner: winner
      }
      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", broadcast_values)
    end

    if res == :win do
      TreasureHunt.PlayerManager.inc_player_revealed_digits_count(winner)
      IO.inspect(TreasureHunt.PlayerManager.get_player(player))
      TreasureHuntWeb.Endpoint.unsubscribe(channel_name) # the player that initiated the game need to unsubscribe
      TreasureHuntWeb.Endpoint.subscribe("game_" <> player) # "player" need to always be connected to channel game_"player"
    end

    state = %{
      game_state: res,
      winner: winner,
      revealed_digits_count: revealed_digits_count
    }
    {:noreply, assign(socket, state)}
  end


  # handle broadcast on the general channel of the game area
  def handle_info(%{topic: "gamearea", event: "join", payload: payload}, socket) do
    IO.puts("HANDLE INFO join: #{inspect(payload)}")

    {:noreply, assign(socket, :players, TreasureHunt.PlayerManager.get_players())}
  end

  # handle broadcast of a given challenge (i.e. game_xy) at the creation of the challenge
  def handle_info(%{topic: "game_" <> opponent, event: "enter_challenge", payload: payload}, socket) do
    IO.puts("HANDLE INFO enter_challenge: #{inspect(payload)}")

    state = %{
      game: inspect(Map.get(payload, :game)),
      game_state: :ok,
      winner: nil,
      channel_name: Map.get(payload, :channel_name)
    }
    #TreasureHuntWeb.Endpoint.broadcast_from(self(), "game_" <> opponent, "update_placeholders", state)

    {:noreply, assign(socket, state)}
  end

  # handle broadcast of a given challenge (i.e. game_xy) when a new answer is given by one of the player
  def handle_info(%{topic: "game_" <> opponent, event: "game_answer", payload: payload}, socket) do
    IO.puts("HANDLE INFO game_answer: #{inspect(payload)}")

    {:noreply, assign(socket, payload)}
  end

  def handle_info(msg, socket) do
    IO.puts("HANDLE INFO other: #{inspect(msg)}")

    {:noreply, socket}
  end

  # Handle rendering of digits
  defp render_digits(random_number, revealed_digits_count) do
    random_number
      |> Integer.digits()
      #|> Enum.reverse()
      |> Enum.with_index()
      |> Enum.map(fn {digit, index} ->
        if index < revealed_digits_count do
          Integer.to_string(digit)
        else
          "*"
        end
      end)
      |> Enum.join(" ")
  end
end