defmodule TreasureHunt.HangmanManager do

  use Agent

  def start_link(player_one,player_two) do
    IO.puts "Hangman game is starting"

    #generate random_word and the hidden word
    random_word = choose_random_word(Path.join([__DIR__, "wordlist.txt"]))
    length = length = String.length(random_word)
    word = String.duplicate(".", length)

    Agent.start_link(fn -> %{:players =>[player_one, player_two],
                            player_one => %{
                              random_word: random_word,
                              word: word,
                              current_answer: false
                            },
                            player_two => %{
                              random_word: random_word,
                              word: word,
                              current_answer: false
                            }} end, name: __MODULE__)
  end

  def reset_values(player_one, player_two) do
    #generate random_word and the hidden word
    random_word = choose_random_word(Path.join([__DIR__, "wordlist.txt"]))
    length = length = String.length(random_word)
    word = String.duplicate(".", length)

    Agent.update(__MODULE__, &(Map.put(&1, player_one, %{
                               random_word: random_word,
                               word: word,
                               current_answer: false
                             })))
    Agent.update(__MODULE__, &(Map.put(&1, player_two, %{
                               random_word: random_word,
                               word: word,
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
    random_word = player_values |> Map.get(:random_word)
    word = player_values |> Map.get(:word)

    case player_current_answer == "try" do
      true ->
        {:guess,player,word,false}
      _ ->
        case player_current_answer == random_word do
          true ->
            TreasureHunt.HangmanManager.reset_values(player_one,player_two)
            {:win,player,random_word,false}
          _ ->
            case String.length(player_current_answer) >= 2 do
              true ->
                case current_player do
                  "player_one" ->
                    {:badtry,player_two,word,player_current_answer}
                  "player_two" ->
                    {:badtry,player_one,word,player_current_answer}
                end
                _ ->
                  updated_word = TreasureHunt.HangmanManager.check_letter(player_current_answer,random_word,word)

                  player_values = Map.put(player_values, :word, updated_word)
                  Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))

                  case current_player do
                    "player_one" ->
                      player2_values = Agent.get(__MODULE__, &(Map.get(&1,player_two)))
                      player2_values = Map.put(player2_values, :word, updated_word)
                      Agent.update(__MODULE__, &(Map.put(&1, player_two, player2_values)))
                    "player_two" ->
                      player2_values = Agent.get(__MODULE__, &(Map.get(&1,player_one)))
                      player2_values = Map.put(player2_values, :word, updated_word)
                      Agent.update(__MODULE__, &(Map.put(&1, player_one, player2_values)))
                  end


                  case updated_word do
                    "no_match" ->
                      player_values = Map.put(player_values, :word, word)
                      Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))

                      case current_player do
                        "player_one" ->
                          player2_values = Agent.get(__MODULE__, &(Map.get(&1,player_two)))
                          player2_values = Map.put(player2_values, :word, word)
                          Agent.update(__MODULE__, &(Map.put(&1, player_two, player2_values)))
                        "player_two" ->
                          player2_values = Agent.get(__MODULE__, &(Map.get(&1,player_one)))
                          player2_values = Map.put(player2_values, :word, word)
                          Agent.update(__MODULE__, &(Map.put(&1, player_one, player2_values)))
                      end
                      case current_player do
                        "player_one" ->
                          {:nomatch,player_two,word,player_current_answer}
                        "player_two" ->
                          {:nomatch,player_one,word,player_current_answer}
                      end
                    _ ->
                      case updated_word == random_word do
                        true ->
                          TreasureHunt.HangmanManager.reset_values(player_one,player_two)
                          {:win,player,updated_word,false}
                        _ ->
                          case current_player do
                            "player_one" ->
                              {:match,player_two,updated_word,player_current_answer}
                            "player_two" ->
                              {:match,player_one,updated_word,player_current_answer}
                          end
                      end

            end





            end



        end

    end

  end


  def update_answer(player, answer) do
    [player_one | [player_two| _]] = Agent.get(__MODULE__,&Map.get(&1, :players))

    player_values = Agent.get(__MODULE__, &(Map.get(&1, player)))

    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))

    player_values = Map.put(player_values, :current_answer, answer)
    Agent.update(__MODULE__, &(Map.put(&1, player, player_values)))

    updated_results = TreasureHunt.HangmanManager.update_results(player)

    updated_results

  end

  def choose_random_word(file_path) do
    case File.read(file_path) do
      {:ok, body} ->
        lines = String.split(body,~r/\r?\n/)
        random_line = Enum.random(lines)
        case random_line do
          nil -> "Error: File is empty."
          line -> line
        end
        {:error, reason} ->
          IO.puts("Error reading file: #{reason}")
          "Error: Unable to read the file."
    end
  end

  defp update_word(random_word, word, guessed_letter) do
    Enum.zip(String.codepoints(random_word), String.codepoints(word))
    |> Enum.map(fn {random_char, current_char} ->
      if random_char == guessed_letter, do: guessed_letter, else: current_char
    end)
    |> List.to_string()
  end

  def check_letter(guessed_letter,random_word,word) do
    random_word_lower = String.downcase(random_word)
    guessed_letter_lower = String.downcase(String.replace(guessed_letter, ~r/\n$/, ""))
    case String.contains?(random_word_lower, guessed_letter_lower) do
      true ->
        updated_word = update_word(random_word_lower, word, guessed_letter_lower)
        IO.puts "Nicely done ! Updated word: #{updated_word}"
        updated_word
      _ ->
        IO.puts "no match"
        "no_match"
    end
  end

end
