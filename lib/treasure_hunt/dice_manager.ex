defmodule TreasureHunt.DiceManager do

  use Agent

  def start_link(player_one,player_two) do
    IO.puts "Dices game is starting"
    Agent.start_link(fn -> %{:players => [player_one, player_two],
                             player_one => %{
                               current_answer: false
                             },
                             player_two => %{
                               current_answer: false
                             },
                             :turn => 0} end, name: __MODULE__)

  end

  def reset_values(player_one, player_two) do
    Agent.update(__MODULE__, &(Map.put(&1, player_one, %{
                               current_answer: false
                             })))
    Agent.update(__MODULE__, &(Map.put(&1, player_two, %{
                               current_answer: false
                             })))
  end

  def update_results() do
    [player_one | [player_two | _]] = Agent.get(__MODULE__, &(Map.get(&1, :players)))

    player_one_values = Agent.get(__MODULE__, &(Map.get(&1, player_one)))
    player_two_values = Agent.get(__MODULE__, &(Map.get(&1, player_two)))
    player_one_current_answer = player_one_values |> Map.get(:current_answer)
    player_two_current_answer = player_two_values |> Map.get(:current_answer)

    result = TreasureHunt.DiceManager.compare_results(player_one_current_answer,player_two_current_answer)
    IO.puts "result of #{player_one} #{player_one_current_answer} and #{player_two} #{player_two_current_answer}"
    case result do
      "player_one" ->
        TreasureHunt.DiceManager.reset_values(player_one,player_two)
        {:win,player_one}
      "player_two" ->
        TreasureHunt.DiceManager.reset_values(player_one,player_two)
        {:win,player_two}
      "tie" ->
        {:ok,"nobody"}
    end
    # player_one_values = Map.put(player_one_values, :current_answer, false)
    # player_two_values = Map.put(player_two_values, :current_answer, false)


  end

 def update_answer(player, answer) do


    player_values = Agent.get(__MODULE__, &(Map.get(&1, player)))
    player_values = Map.put(player_values, :current_answer, answer)
    #IO.puts inspect(player_values)
    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))
    Agent.update(__MODULE__, &(Map.put(&1, :turn, Map.get(&1, :turn) + 1)))

    case rem(Agent.get(__MODULE__, &(Map.get(&1, :turn))), 2) do
      0 ->
        updated_results = TreasureHunt.DiceManager.update_results()
        updated_results
      _  ->
        {:wait, nil}
    end

  end

  def compare_results(value1,value2) do
    #IO.puts "COMPARING #{value1} and #{value2}"
    case {value1,value2} do
      {nil, _} ->
        IO.puts("Waiting for Player 1 to roll.")
      {_, nil} ->
        IO.puts("Waiting for Player 2 to roll.")
      {p1, p2} when p1 > p2 ->
        IO.puts("Player 1 wins with a roll of #{p1}!")
        "player_one"
      {p1, p2} when p2 > p1 ->
        IO.puts("Player 2 wins with a roll of #{p2}!")
        "player_two"
      {p1, p2} when p1 == p2 ->
        IO.puts("It's a tie! Both players rolled #{p1}.")
        "tie"
    end
  end


end
