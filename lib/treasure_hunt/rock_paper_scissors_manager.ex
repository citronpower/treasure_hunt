defmodule TreasureHunt.RockPaperScissorsManager do

  use Agent

  def start_link(player_id,opponent_id,game_manager_id) do
    IO.puts "Rock Paper Scissors game is starting"

    player1 = player_id
    player2 = opponent_id

    player1 = spawn(fn -> shifumi1(player1) end)
    player2 = spawn(fn -> shifumi2(player2) end)

    win1 = 0
    win2 = 0

    engine = spawn(fn -> engine(player_id,opponent_id,player1,player2,game_manager_id,win1,win2) end)
    send(engine,{:init})
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

  def compare_choices(choice1,choice2) do
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
