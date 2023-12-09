defmodule TreasureHunt.GuessTheNumberManager do

  use Agent

  def start_link(player_id, opponent_id) do
    Agent.start_link(fn -> %{player: player_id, opponent: opponent_id} end, name: __MODULE__)

    IO.puts "Guess the number is starting, the number you have to find is between 1 and 50"

#    player1 = player_id
#    player2 = opponent_id

    #generate random number between 0 ans 50
#    random_number = :rand.uniform(50)
#
#    #spawing the processes
#    player1 = spawn(fn->guess(player1) end)
#    player2 = spawn(fn->guess(player2) end)
#
#    #spawn the game master
#    engine = spawn(fn->engine(player_id,opponent_id, player1, player2, random_number,game_manager_id) end)
#    send(engine, {:init})
  end

  @doc """
  Engine of the game
  """
  def engine(player_id, opponent_id, player1, player2, random_number, game_manager_id) do
    receive do
      {:init} ->
        #IO.puts "#{inspect(player1)} #{inspect(player2)} #{random_number}"
        Process.sleep(100) #I don't know why it doesn't work without that
        #start the game
        send(player1,{:play, self()})

      {:guess, guessed_number, source} ->
        result = compare_number(random_number,guessed_number)

        if result != "equal" do
          IO.puts "The number is #{result}"
        end

        next =
          cond do
            source == player1 -> player2
            source == player2 -> player1
          end

        cond do
          result != "equal" -> send(next, {:play, self()})
          result == "equal" -> send(self(), {:end_game,source})
        end

        {:end_game, winner} ->
          cond do
            winner == player1 -> send(game_manager_id,{:endgame,player_id})
            winner == player2 -> send(game_manager_id,{:endgame,opponent_id})
            true -> send(game_manager_id,{:endgame,"no"})
          end
          #IO.puts "The winner is #{name} !"
          #Process.sleep(2000) #to ensure the victory message is printed
          #send(game_manager_id,{:endgame,name}) #end-game
          Process.exit(player1, :normal)
          Process.exit(player2, :normal)
          Process.exit(self(), :normal)

    end

    engine(player_id,opponent_id, player1, player2, random_number,game_manager_id)
  end

  def guess(player_id) do
    receive do
      {:play, source} ->
        #IO.puts "#{player_id}: received start"
        guessed_number = check_error(player_id)
        send(source,{:guess,guessed_number,self()})
    end
    guess(player_id)
  end

  defp compare_number(random_number,guessed_number) do
    cond do
      guessed_number == random_number -> "equal"
      guessed_number > random_number -> "lower"
      guessed_number < random_number -> "bigger"
    end
  end

  defp check_error(player_id) do
    input = IO.gets("#{player_id}, please guess a number: ")
        case input |> Integer.parse() do
          {guessed_number,rest} ->
            case rest do
              "\n" ->
                case guessed_number >= 1 and guessed_number <= 50 do
                  true ->
                    guessed_number
                  _ ->
                    IO.puts "Invalid input. Please enter a number between 1 and 50"
                    check_error(player_id)
                end
              _ ->
                IO.puts("Invalid input. Please enter a valid number.")
                check_error(player_id)
            end
          _ ->
            IO.puts("Invalid input. Please enter a valid number.")
            check_error(player_id)
        end
  end

end
