defmodule TreasureHunt.RockPaperScissorsManager do

  use Agent

  def start_link(player_one, player_two) do
    IO.puts "Rock Paper Scissors game is starting"
    Agent.start_link(fn -> %{:players => [player_one, player_two],
                             player_one => %{
                               score: 0,
                               current_answer: false
                             },
                             player_two => %{
                               score: 0,
                               current_answer: false
                             },
                             :round => 0} end, name: __MODULE__)
#    player1 = player_id
#    player2 = opponent_id
#
#    player1 = spawn(fn -> shifumi1(player1) end)
#    player2 = spawn(fn -> shifumi2(player2) end)
#
#    win1 = 0
#    win2 = 0
#
#    engine = spawn(fn -> engine(player_id,opponent_id,player1,player2,game_manager_id,win1,win2) end)
#    send(engine,{:init})
  end

  def verify_score(score) do

  end

  def update_results() do
    [player_one | [player_two | _]] = Agent.get(__MODULE__, &(Map.get(&1, :players)))

    IO.puts("player_one")
    IO.puts(inspect(player_one))
    IO.puts(inspect(Agent.get(__MODULE__, &(Map.get(&1, player_one)))))
    IO.puts("player_two")
    IO.puts(inspect(player_two))

    player_one_values = Agent.get(__MODULE__, &(Map.get(&1, player_one)))
    player_two_values = Agent.get(__MODULE__, &(Map.get(&1, player_two)))

    player_one_current_answer = player_one_values |>
      Map.get(:current_answer)

    player_two_current_answer = player_two_values |>
      Map.get(:current_answer)

    player_one_score = player_one_values |>
      Map.get(:score)

    player_two_score = player_two_values |>
      Map.get(:score)

    IO.puts(inspect(player_one_current_answer))
    IO.puts(inspect(player_two_current_answer))
    result = TreasureHunt.RockPaperScissorsManager.compare_choices(player_one_current_answer, player_two_current_answer)
    IO.puts("And the winner is???")
    IO.puts(inspect(result))
    case result do
      :player_one ->
        IO.puts("Player oneeeeeeeeeeeeee")
        player_one_score = player_one_score + 1
        IO.puts(player_one_score)

        case player_one_score >= 3 do
          true ->
            {:win, player_one}
          false ->
            IO.puts(player_one_score)
            player_one_values = Map.put(player_one_values, :score, player_one_score)
            IO.puts(inspect(player_one_values))
            Agent.update(__MODULE__, &(Map.put(&1, player_one, player_one_values)))
            {:ok, player_one}
        end
      :player_two ->
        IO.puts("Player twoooooooooooo")
        player_two_score = player_two_score + 1
        IO.puts(player_two_score)

        case player_two_score >= 3 do
          true ->
            {:win, player_two}
          false ->
            player_two_values = Map.put(player_two_values, :score, player_two_score)
            Agent.update(__MODULE__, &(Map.put(&1, player_two, player_two_values)))
            {:ok, player_two}
        end

      :tie ->
        IO.puts("Tie....")
        {:ok, "nobody"}
      _ ->
        {:error, nil}
    end
#    IO.puts("pfff")
#    IO.puts(player_one_score)
#    IO.puts(player_two_score)
#    player_one_score = Agent.get(__MODULE__, &(Map.get(&1, player_one))) |> Map.get(:score)
#    player_two_score = Agent.get(__MODULE__, &(Map.get(&1, player_two))) |> Map.get(:score)

    #IO.puts(inspect(Agent.get(__MODULE__, &(&1))))
    #{result, %{player_one => Agent.get(__MODULE__, &(Map.get(&1, player_one))) |> Map.get(:current)}, %{player_two => player_two_score}}

  end

  def update_answer(player, answer) do

    player_values = Agent.get(__MODULE__, &(Map.get(&1, player)))
    player_values = Map.put(player_values, :current_answer, answer)

    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))
    Agent.update(__MODULE__, &(Map.put(&1, :round, Map.get(&1, :round) + 1)))

    case rem(Agent.get(__MODULE__, &(Map.get(&1, :round))), 2) do
      0 ->
        Agent.update(__MODULE__, &(Map.put(&1, :round, Map.get(&1, :round) + 1)))
        updated_results = TreasureHunt.RockPaperScissorsManager.update_results()
        IO.puts(inspect(updated_results))
        updated_results
      _ ->
        {:wait, nil}
    end
  end

  def compare_choices(answer_one, answer_two) do
    #IO.puts "COMPARING #{choice1} and #{choice2}"
    case {answer_one, answer_two} do
      {"paper","rock"} ->
        IO.puts "Player1 won"
        :player_one
      {"paper","scissor"} ->
        IO.puts "Player2 won"
        :player_two
      {"paper","paper"} ->
        IO.puts "It's a tie"
        :tie
      {"rock","paper"} ->
        IO.puts "Player2 won"
        :player_two
      {"rock","scissor"} ->
        IO.puts "Player1 won"
        :player_one
      {"rock", "rock"} ->
        IO.puts "It's a tie"
        :tie
      {"scissor","paper"} ->
        IO.puts "Player1 won"
        :player_one
      {"scissor","rock"} ->
        IO.puts "Player2 won"
        :player_two
      {"scissor","scissor"} ->
        IO.puts "It's a tie"
        :tie
    end
  end

  def engine(player_id,opponent_id,player1,player2,game_manager_id,win1,win2) do
    receive do
      {:init} ->
        send(player1,{:play,self(),player1,player2,win1,win2})

        {:shifumi, winner,win1,win2} ->
          #IO.puts "do we need another round ?"
          #pr enable les 3 round
          {win1, win2} =
          cond do
            winner == "player1" -> {win1 + 1, win2}
            winner == "player2" -> {win1, win2 + 1}
            true -> {win1, win2}
          end
          #IO.puts "1 = #{win1} and 2 = #{win2}"
          cond do
            win1 + win2 < 3 -> send(player1,{:play,self(),player1,player2,win1,win2})
            win1 + win2 == 3 -> send(self(),{:end_game,win1,win2})
            true -> nil
          end

        {:end_game,win1,win2} ->
            cond do
              win1 >win2 -> send(game_manager_id,{:endgame,player_id})
              win1 < win2  -> send(game_manager_id,{:endgame,opponent_id})
              true -> send(game_manager_id,{:endgame,"no"})
            end
            Process.exit(player1, :normal)
            Process.exit(player2, :normal)
            Process.exit(self(), :normal)
    end
    engine(player_id,opponent_id,player1,player2,game_manager_id,win1,win2)
  end

  def shifumi1(player_id) do
    receive do
      {:play, source, current, next,win1,win2} ->
        choice = check_error(player_id)
        send(next, {:play,choice,current,next,source,win1,win2})
    end
    shifumi1(player_id)
  end

  def shifumi2(player_id) do
    receive do
      {:play,choice1,next,current,source,win1,win2} ->
        choice2 = check_error(player_id)
        winner = compare_choices(choice1,choice2)
        cond do
          winner == "tie" -> send(next,{:play,source,next,current,win1,win2})
          true -> send(source,{:shifumi, winner,win1,win2})
        end
    end
    shifumi2(player_id)
  end

  def compare_choices2(choice1,choice2) do
    #IO.puts "COMPARING #{choice1} and #{choice2}"
    case {String.downcase(String.trim(choice1)),String.downcase(String.trim(choice2))} do
      {"paper","rock"} ->
        IO.puts "Player1 won"
        "player1"
      {"paper","scissors"} ->
        IO.puts "Player2 won"
        "player2"
      {"paper","paper"} ->
        IO.puts "It's a tie"
        "tie"
      {"rock","paper"} ->
        IO.puts "Player2 won"
        "player2"
      {"rock","scissors"} ->
        IO.puts "Player1 won"
        "player1"
      {"rock", "rock"} ->
        IO.puts "It's a tie"
        "tie"
      {"scissors","paper"} ->
        IO.puts "Player1 won"
        "player1"
      {"scissors","rock"} ->
        IO.puts "Player2 won"
        "player2"
      {"scissors","scissors"} ->
        IO.puts "It's a tie"
        "tie"
    end
  end



  def check_error(player_id) do
    input = IO.gets("#{player_id}, rock, paper, scissors ?")
    case String.downcase(String.trim(input)) do
      "rock" ->
        input
      "paper" ->
        input
      "scissors" ->
        input
      _ ->
         IO.puts("Invalid input.")
         check_error(player_id)
    end
  end

end
