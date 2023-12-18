defmodule TreasureHunt.GuessTheNumberManager do

  use Agent

  def start_link(player_one, player_two) do
    IO.puts "Guess the number is starting, the number you have to find is between 1 and 50"
    #generate random number between 0 ans 50
    random_number = :rand.uniform(50)
    Agent.start_link(fn -> %{:players =>[player_one, player_two],
                            player_one => %{
                              random_number: random_number,
                              current_answer: false
                            },
                            player_two => %{
                              random_number: random_number,
                              current_answer: false
                            }} end, name: __MODULE__)
  end



  def reset_values(player_one, player_two) do
    Agent.update(__MODULE__, &(Map.put(&1, player_one, %{
                               random_number: false,
                               current_answer: false
                             })))
    Agent.update(__MODULE__, &(Map.put(&1, player_two, %{
                               random_number: false,
                               current_answer: false
                             })))
  end


  def update_results(player) do
    [player_one | [player_two| _]] = Agent.get(__MODULE__,&Map.get(&1, :players))

    current_player =
    cond do
      player == player_one -> "player_one"
      player == player_two -> "opponent_two"
    end

    IO.puts "current one is #{current_player}"

    player_values =
    case current_player do
      "player_one" ->
        IO.puts "player oneone"
        Agent.get(__MODULE__, &(Map.get(&1,player_one)))
      "player_two" ->
        IO.puts "player twotwo"
        Agent.get(__MODULE__, &(Map.get(&1,player_two)))
    end

    # player_one_values = Agent.get(__MODULE__, &(Map.get(&1,player_one)))
    # player_two_values = Agent.get(__MODULE__, &(Map.get(&1,player_two)))
    # player_one_current_answer = player_id_values |> Map.get(:current_answer)
    # player_two_current_answer = opponent_id_values |> Map.get(:current_answer)


    player_current_answer = player_values |> Map.get(:current_answer)
    random_number = player_values |> Map.get(:random_number)

    result = TreasureHunt.GuessTheNumberManager.compare_number(random_number,player_current_answer)
    IO.puts "result of #{random_number} and #{player_current_answer} is #{result}"

    case result do
      "equal" ->
        TreasureHunt.GuessTheNumberManager.reset_values(player_one,player_two)
        {:win,player,player_current_answer,false}
      "lower" ->
        case player do
          player_one ->
            {:lower,player_two,player_current_answer}
            #{:wait,player,player_current_answer,"lower"}
          player_two ->
            {:lower,player_one,player_current_answer}
            #{:wait,player,player_current_answer,"lower"}
        end

      "bigger" ->
        case player do
          player_one ->
            {:bigger,player_two,player_current_answer}
            #{:wait,player,player_current_answer,"bigger"}
          player_two ->
            {:bigger,player_one,player_current_answer}
            #{:wait,player,player_current_answer,"bigger"}
        end
    end
  end

  def update_answer(player, answer) do
    [player_one | [player_two| _]] = Agent.get(__MODULE__,&Map.get(&1, :players))
    IO.puts "updating answer"
    player_values = Agent.get(__MODULE__, &(Map.get(&1, player)))

    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))

    updated_results =
    case answer |> Integer.parse() do
      {guessed_number, rest} ->
        case rest do
          "" ->
            case guessed_number >= 1 and guessed_number <= 50 do
              true ->
                IO.puts "Valid input: #{guessed_number}"
                player_values = Map.put(player_values, :current_answer, guessed_number)
                Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))
                IO.puts inspect(player_values)
                TreasureHunt.GuessTheNumberManager.update_results(player)
              _ ->
                IO.puts "Invalid input"
                case player do
                  player_one ->
                    {:error, player,answer,false}
                  player_two ->
                    {:error, player,answer,false}
                end
            end
          _ ->
            IO.puts "Invalid input"
            case player do
              player_one ->
                {:error, player,answer,false}
              player_two ->
                {:error, player,answer,false}
            end
          end
      _ ->
        IO.puts "Invalid input"
        case player do
          player_one ->
            {:error, player,answer,false}
          player_two ->
            {:error, player,answer,false}
        end
    end

    # if check_input == :invalid do
    #   IO.puts "sending not valid"
    #   case player do
    #     player_one ->
    #       {:error, player,answer,false}
    #     player_two ->
    #       {:error, player,answer,false}
    #   end
    # end

    updated_results



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

  def compare_number(random_number,guessed_number) do
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
