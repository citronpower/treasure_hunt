defmodule TreasureHunt.DiceManager do

  use Agent

  def start_link(player_id,opponent_id,game_manager_id) do
    IO.puts "Dices game is starting"

    player1 = player_id
    player2 = opponent_id

    player1 = spawn(fn -> roll1(player1) end)
    player2 = spawn(fn -> roll2(player2) end)

    engine = spawn(fn -> engine(player_id,opponent_id,player1,player2,game_manager_id) end)
    send(engine, {:init})
  end

  def engine(player_id,opponent_id,player1,player2,game_manager_id) do
    receive do
      {:init} ->
        send(player1,{:play,self(),player2})

      #process results
      {:roll,result1,result2, source1,source2}  ->
        IO.puts("#{source1} rolled #{result1},#{source2} rolled #{result2} ")
        winner = compare_results(result1,result2)
        send(self(),{:end_game,winner})

      #sends results to game manager
      {:end_game,winner} ->
        cond do
          winner == "player1" -> send(game_manager_id,{:endgame,player_id})
          winner == "player2" -> send(game_manager_id,{:endgame,opponent_id})
          winner == "tie" -> send(game_manager_id,{:endgame, "tie"})
          true -> send(game_manager_id,{:endgame,"no"})
        end
        Process.exit(player1, :normal)
        Process.exit(player2, :normal)
        Process.exit(self(), :normal)
    end
    engine(player_id,opponent_id,player1,player2,game_manager_id)
  end

  def roll1(player_id) do
    receive do
      {:play,source,next} ->
        check_error(player_id)
        result = :rand.uniform(6)
        #IO.puts "#{player_id} rolled #{result}"
        send(next,{:play,result,player_id,source})
    end
  end

  def roll2(player_id) do
    receive do
      {:play,result1,source1,source} ->
        check_error(player_id)
        result2 = :rand.uniform(6)
        #IO.puts "#{player_id} rolled #{result2}"
        send(source,{:roll,result1,result2,source1,player_id})
    end
  end

  defp compare_results(value1,value2) do
    #IO.puts "COMPARING #{value1} and #{value2}"
    case {value1,value2} do
      {nil, _} ->
        IO.puts("Waiting for Player 1 to roll.")
      {_, nil} ->
        IO.puts("Waiting for Player 2 to roll.")
      {p1, p2} when p1 > p2 ->
        IO.puts("Player 1 wins with a roll of #{p1}!")
        "player1"
      {p1, p2} when p2 > p1 ->
        IO.puts("Player 2 wins with a roll of #{p2}!")
        "player2"
      {p1, p2} when p1 == p2 ->
        IO.puts("It's a tie! Both players rolled #{p1}.")
        "tie"
    end
  end

  defp check_error(player_id) do
    input = IO.gets("#{player_id}, are you ready to roll? [Yes/No] ")
    case String.downcase(String.trim(input)) do
      "yes" ->
        input
      "no" ->
        IO.puts("Alright, take your time.")
        check_error(player_id)
      _ ->
        IO.puts("Invalid input.")
        check_error(player_id)
    end
  end
end
