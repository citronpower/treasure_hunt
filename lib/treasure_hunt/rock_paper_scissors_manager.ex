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
  end

  def reset_values(player_one, player_two) do
    Agent.update(__MODULE__, &(Map.put(&1, player_one, %{
                               score: 0,
                               current_answer: false
                             })))
    Agent.update(__MODULE__, &(Map.put(&1, player_two, %{
                               score: 0,
                               current_answer: false
                             })))
  end

  def update_results() do
    [player_one | [player_two | _]] = Agent.get(__MODULE__, &(Map.get(&1, :players)))

    player_one_values = Agent.get(__MODULE__, &(Map.get(&1, player_one)))
    player_two_values = Agent.get(__MODULE__, &(Map.get(&1, player_two)))
    player_one_current_answer = player_one_values |> Map.get(:current_answer)
    player_two_current_answer = player_two_values |> Map.get(:current_answer)
    player_one_score = player_one_values |> Map.get(:score)
    player_two_score = player_two_values |> Map.get(:score)

    result = TreasureHunt.RockPaperScissorsManager.compare_choices(player_one_current_answer, player_two_current_answer)

    player_one_values = Map.put(player_one_values, :current_answer, false)
    player_two_values = Map.put(player_two_values, :current_answer, false)

    case result do
      :player_one ->
        player_one_score = player_one_score + 1

        case player_one_score >= 3 do
          true ->
            TreasureHunt.RockPaperScissorsManager.reset_values(player_one, player_two)
            {:win, player_one}
          false ->
            player_one_values = Map.put(player_one_values, :score, player_one_score)
            Agent.update(__MODULE__, &(Map.put(&1, player_one, player_one_values)))
            {:win, player_one}
        end
      :player_two ->
        player_two_score = player_two_score + 1

        case player_two_score >= 3 do
          true ->
            TreasureHunt.RockPaperScissorsManager.reset_values(player_one, player_two)
            {:win, player_two}
          false ->
            player_two_values = Map.put(player_two_values, :score, player_two_score)
            Agent.update(__MODULE__, &(Map.put(&1, player_two, player_two_values)))
            {:win, player_two}
        end

      :tie ->
        IO.puts("Tie....")
        {:ok, "nobody"}
      _ ->
        {:error, nil}
    end
  end

  def update_answer(player, answer) do

    player_values = Agent.get(__MODULE__, &(Map.get(&1, player)))
    player_values = Map.put(player_values, :current_answer, answer)

    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))
    Agent.update(__MODULE__, &(Map.put(&1, :round, Map.get(&1, :round) + 1)))

    case rem(Agent.get(__MODULE__, &(Map.get(&1, :round))), 2) do
      0 ->
        updated_results = TreasureHunt.RockPaperScissorsManager.update_results()
        updated_results
      _ ->
        {:wait, nil}
    end
  end

  def compare_choices(answer_one, answer_two) do
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

end