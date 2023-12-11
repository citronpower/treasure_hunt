defmodule TreasureHunt.GameManager do
use Agent

  # Start the Agent with the initial state
  def start_link(little_games) do
    Agent.start_link(fn -> %{little_games: little_games, challenges: []} end, name: __MODULE__)
  end

  # Your functions for managing game state
  def get_little_games() do
    Agent.get(__MODULE__, &(&1.little_games))
  end

  def get_random_game() do
    List.first(Enum.shuffle(get_little_games()))
  end

#  def start_game(game, player_one, player_two) do
#    IO.puts("Start game")
#    Agent.start_link(game, [player_one, player_two])
#  end

  def get_challenges(player) do
    challenges = Agent.get(__MODULE__, &(&1.challenges))
    Enum.filter(challenges, fn %{player_one: p1, player_two: p2} ->
      p1 == player or p2 == player
    end)
  end

  def verify_challenges(game, player1, player2) do
    challenges = Agent.get(__MODULE__, &(&1.challenges))
    filtered_challenges = Enum.filter(challenges, fn %{game: g, player_one: p1, player_two: p2} ->
      ((p1 == player1 and p2 == player2) or (p1 == player2 and p2 == player1)) and g == game
    end)
    length(filtered_challenges) > 0
  end

  def add_challenge(game, player1, player2) do
    IO.puts("add_challenge")

    if ! verify_challenges(game, player1, player2) do
      challenge = %{}

      player_one = if player1 > player2, do: player2, else: player1 # strange behaviour! (not working!)
      player_two = if player1 < player2, do: player1, else: player2

      challenge = Map.put(challenge, :player_one, player1) |>
        Map.put(:player_two, player2)  |>
        Map.put(:game, game)
      Agent.update(__MODULE__, &(Map.put(&1, :challenges, [challenge | &1.challenges])))
    end

  end

  #defp update_state(update_fun) do
  #  Agent.update(__MODULE__, update_fun)
  #end

# Little Games 
#    def get_little_Games() do
#    [
#      %{name: "Hangman", code: :hangman},
#      %{name: "Guessing the Number", code: :number_guess},
#      %{name: "Rock Paper Scissors", code: :rock_paper_scissors},
#      %{name: "Dice", code: :dice}
#    ]
#    end

# Challenges

    # Function to initiate the process
    def choose_game(player_id) do
        # Get opponent
        opponent_id = get_opponent(player_id) #Until Button-Click implemented
        case get_opponent(opponent_id) do
          {:ok, opponent_id} ->

            # Get a random order of little games
            little_games = get_little_games()
            shuffled_games = Enum.shuffle(little_games)

            # Start Challenge with randomized little games
            initiate_challenge(player_id, opponent_id, shuffled_games)
          {:error, reason} ->
            IO.puts("Error: #{reason}")
        end
    end 

    def initiate_challenge(player_id, opponent_id) do
      IO.puts("Initiating Challenge between #{player_id} and #{opponent_id}")
      game = TreasureHunt.GameManager.get_random_game()
      IO.puts("TTTTT")
      IO.puts(inspect(game))

      TreasureHunt.GameManager.add_challenge(game, player_id, opponent_id)
      #Supervisor.start_link({game, [player_id, opponent_id]}, [strategy: :one_for_one, name: TreasureHunt.Supervisor])
    end

    defp initiate_challenge(player_id, opponent_id, shuffled_games) do 
         IO.puts("Initiating Challenge between #{player_id} and #{opponent_id}")

        # Iterate through the randomized games
#        Enum.each(shuffled_games, fn game ->
#            case game.code do
#                :guessing_number -> initiate_guessing_number(player_id, opponent_id)
#                _ -> IO.puts("Invalid game choice")
#            end
#        end)

        IO.puts("Challenge (Round 1) completed between #{player_id} and #{opponent_id}")
    end

#    def handle_challenge_result(challenger_id, opponent_id, result) do 
#        # Implement logic 
#    end 

#Update Player State after little games 

    def update_player_score(player_id, result) do
        case result do
            :win ->
                # Implement logic to update the score when the player wins
                {:ok, "You won! Your score is updated."}

            :lose ->
                # Implement logic to handle the case when the player loses
                {:ok, "You lost. Your score remains unchanged."}

            _ ->
                # Implement resulting error if needed
                IO.puts("Error. Score not updated!")
        end
    end


# Private Helper Functions 

    # Function to get opponent for a player 
    defp get_opponent(opponent_id) do
        # Check if the chosen opponent is available
        case TreasureHunt.PlayerManager.get_player(opponent_id) do
            {:ok, opponent_state} ->
                {:ok, opponent_id}
    
            {:error, _} ->
                {:error, "Chosen opponent is not available"}
        end
    end

#    #Helper Function to find the next available opponent
#    defp find_next_opponent(player_id, all_players) do
#        # Might need modification (IDEA)
#        available_opponents =
#            Enum.filter(all_players, fn {id, state} ->
#                id != player_id && Map.get(state, :opponent) == nil
#            end)

#        if length(available_opponents) > 0 do
#            randomly_selected_opponent = Enum.random(available_opponents)
#            {opponent_id, _} = randomly_selected_opponent
#            {:ok, opponent_id}
#        else
#            {:error, "No available opponents"}
#        end
#    end

    # Initiate Guessing Number Game
    defp initiate_guessing_number(player_id, opponent_id) do 
        IO.puts("Initiating Guessing Number between #{player_id} and #{opponent_id}")
    end 
end