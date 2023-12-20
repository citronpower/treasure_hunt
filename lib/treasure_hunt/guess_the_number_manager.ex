defmodule TreasureHunt.GuessTheNumberManager do

  use Agent

  def start_link(player_one, player_two) do
    IO.puts "Guess the number is starting, the number you have to find is between 1 and 50"
    #generate random number between 1 ans 50
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
    random_number = :rand.uniform(50)
    Agent.update(__MODULE__, &(Map.put(&1, player_one, %{
                               random_number: random_number,
                               current_answer: false
                             })))
    Agent.update(__MODULE__, &(Map.put(&1, player_two, %{
                               random_number: random_number,
                               current_answer: false
                             })))
  end


  def update_results(player) do
    [player_one | [player_two| _]] = Agent.get(__MODULE__,&Map.get(&1, :players))

    current_player =
    cond do
      player == player_one -> "player_one"
      player == player_two -> "player_two"
    end


    player_values =
    case current_player do
      "player_one" ->
        Agent.get(__MODULE__, &(Map.get(&1,player_one)))
      "player_two" ->
        Agent.get(__MODULE__, &(Map.get(&1,player_two)))
    end

    player_current_answer = player_values |> Map.get(:current_answer)
    random_number = player_values |> Map.get(:random_number)

    result = TreasureHunt.GuessTheNumberManager.compare_number(random_number,player_current_answer)

    case result do
      "equal" ->
        TreasureHunt.GuessTheNumberManager.reset_values(player_one,player_two)
        {:win,player,player_current_answer}
      "lower" ->
        case current_player do
          "player_one" ->
            {:lower,player_two,player_current_answer}
          "player_two" ->
            {:lower,player_one,player_current_answer}
        end

      "bigger" ->
        case current_player do
          "player_one" ->
            {:bigger,player_two,player_current_answer}
          "player_two" ->
            {:bigger,player_one,player_current_answer}
          _ ->
            "no match man :("
        end
    end
  end

  def update_answer(player, answer) do
    [player_one | [player_two| _]] = Agent.get(__MODULE__,&Map.get(&1, :players))

    player_values = Agent.get(__MODULE__, &(Map.get(&1, player)))

    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))

    {guessed_number, rest}  = answer |> Integer.parse()


    player_values = Map.put(player_values, :current_answer, guessed_number)
    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))

    IO.puts inspect(player_values)
    updated_results = TreasureHunt.GuessTheNumberManager.update_results(player)

    updated_results

  end

  def compare_number(random_number,guessed_number) do
    cond do
      guessed_number == random_number -> "equal"
      guessed_number > random_number -> "lower"
      guessed_number < random_number -> "bigger"
    end
  end

end
