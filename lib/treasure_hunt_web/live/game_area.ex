defmodule TreasureHuntWeb.GameArea do
  use TreasureHuntWeb, :live_view

  @topic "gamearea"

  # initiate
  def mount(_params, session, socket) do
    TreasureHuntWeb.Endpoint.subscribe(@topic) # general channel for all players

    player = Map.get(session, "_csrf_token") # fancy name of the player

    if player != nil do
      TreasureHuntWeb.Endpoint.subscribe(player) # specific channel for a given player
    end

    state = %{
      player: player,
      random_number: nil,
      revealed_digits_count: 0,
      joined: false,
      game: false,
      game_won: false,
      win: false
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
      joined: true,
      win: false
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
      revealed_digits_count: revealed_digits_count,
      player_one: player,
      player_two: opponent
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

    if res == :win do
      TreasureHunt.PlayerManager.inc_player_revealed_digits_count(winner)

      TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{revealed_digits_count:
        TreasureHunt.PlayerManager.get_player_revealed_digits_count(winner)})
      # Implement Game Over scenario
      if TreasureHunt.PlayerManager.player_below_revealed_digits_limit?(winner) do
        IO.puts("Game Over!")
        TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{win: true})
      end

      TreasureHuntWeb.Endpoint.unsubscribe(channel_name) # the player that initiated the game need to unsubscribe
      TreasureHuntWeb.Endpoint.subscribe("game_" <> player) # "player" need to always be connected to channel game_"player"
    end

    state = %{
      game_state: res,
      winner: winner
    }
    {:noreply, assign(socket, state)}
  end

# handle the click on the start button of dice game
  def handle_event("game_answer", %{"answer" => answer, "game" => "TreasureHunt.DiceManager", "player" => player, "channel_name" => channel_name, "value" => _}, socket) do
    IO.puts("HANDLE EVENT game_answer")

    answer =
    case answer do
      "go" ->
        IO.puts "Hello me in changing answer"
        :rand.uniform(6)
      _ ->
        answer
    end
    IO.puts "answer is #{answer}"
    {res, winner} = TreasureHunt.DiceManager.update_answer(player, answer)

    if res != :wait do
      broadcast_values = %{
        game_state: res,
        winner: winner
      }
      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", broadcast_values)
    end

    if res == :win do
      TreasureHunt.PlayerManager.inc_player_revealed_digits_count(winner)

      # Implement Game Over scenario
      if TreasureHunt.PlayerManager.player_below_revealed_digits_limit?(winner) do
        IO.puts("Game Over!")
        TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{win: true})
      end
      TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{revealed_digits_count: TreasureHunt.PlayerManager.get_player_revealed_digits_count(winner)})
      TreasureHuntWeb.Endpoint.unsubscribe(channel_name) # the player that initiated the game need to unsubscribe
      TreasureHuntWeb.Endpoint.subscribe("game_" <> player) # "player" need to always be connected to channel game_"player"
    end

    state = %{
      game_state: res,
      winner: winner
    }
    {:noreply, assign(socket, state)}
  end

  #handle the input in the guess_the_number game
  def handle_event("game_answer", %{"answer" => answer, "game" => "TreasureHunt.GuessTheNumberManager", "player" => player, "channel_name" => channel_name}, socket) do
    IO.puts("HANDLE EVENT game_answer")

    IO.puts "game area player is #{player}"
    {res, winner, guessed_number} = TreasureHunt.GuessTheNumberManager.update_answer(player, answer)

    if res != :win do

      broadcast_values = %{
        game_state: res,
        winner: winner,
        number: guessed_number
      }

      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", broadcast_values)
    end

    if res == :win do
    TreasureHunt.PlayerManager.inc_player_revealed_digits_count(winner)
    # Implement Game Over scenario
      if TreasureHunt.PlayerManager.player_below_revealed_digits_limit?(winner) do
        IO.puts("Game Over!")
        TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{win: true})
      end

      TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{revealed_digits_count: TreasureHunt.PlayerManager.get_player_revealed_digits_count(winner)})

      broadcast_values = %{
        game_state: res,
        winner: winner,
        number: guessed_number
      }

      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", broadcast_values)
      TreasureHuntWeb.Endpoint.unsubscribe(channel_name)
      TreasureHuntWeb.Endpoint.subscribe("game_" <> player)
    end

    state = %{
      game_state: res,
      winner: winner,
      number: guessed_number
    }
    {:noreply, assign(socket, state)}
  end

  #handle the input in the hangman game
  def handle_event("game_answer", %{"answer" => answer, "game" => "TreasureHunt.HangmanManager", "player" => player, "channel_name" => channel_name}, socket) do
    IO.puts("HANDLE EVENT game_answer")

    IO.puts "game area player is #{player}"
    {res, winner, word,last_try} = TreasureHunt.HangmanManager.update_answer(player, answer)

    if res != :win do

      broadcast_values = %{
        game_state: res,
        winner: winner,
        word: word,
        last_try: last_try
      }

      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", broadcast_values)
    end

    if res == :win do
      TreasureHunt.PlayerManager.inc_player_revealed_digits_count(winner)
      # Implement Game Over scenario
      if TreasureHunt.PlayerManager.player_below_revealed_digits_limit?(winner) do
        IO.puts("Game Over!")
        TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{win: true})
      end

      TreasureHuntWeb.Endpoint.broadcast(winner, "message", %{revealed_digits_count: TreasureHunt.PlayerManager.get_player_revealed_digits_count(winner)})

      broadcast_values = %{
        game_state: res,
        winner: winner,
        word: word
      }

      TreasureHuntWeb.Endpoint.broadcast_from(self(), channel_name, "game_answer", broadcast_values)
      TreasureHuntWeb.Endpoint.unsubscribe(channel_name)
      TreasureHuntWeb.Endpoint.subscribe("game_" <> player)
    end

    state = %{
      game_state: res,
      winner: winner,
      word: word
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

    IO.puts inspect(payload)

    state = %{
      game: inspect(Map.get(payload, :game)),
      game_state: :ok,
      winner: nil,
      channel_name: Map.get(payload, :channel_name),
      player_one: Map.get(payload, :player_one),
      player_two: Map.get(payload, :player_two)
    }
    #TreasureHuntWeb.Endpoint.broadcast_from(self(), "game_" <> opponent, "update_placeholders", state)

    {:noreply, assign(socket, state)}
  end

  # handle broadcast of a given challenge (i.e. game_xy) when a new answer is given by one of the player
  def handle_info(%{topic: "game_" <> opponent, event: "game_answer", payload: payload}, socket) do
    IO.puts("HANDLE INFO game_answer: #{inspect(payload)}")

    {:noreply, assign(socket, payload)}
  end

  def handle_info(%{topic: player, event: "message", payload: payload}, socket) do
    IO.puts("HANDLE INFO message for #{inspect(player)}}: #{inspect(payload)}")

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
