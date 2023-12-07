defmodule TreasureHunt.Hangman do

  def start(player_id,opponent_id,game_manager_id) do
    IO.puts "Hangman game is starting"

    player1 = player_id
    player2 = opponent_id

    player1 = spawn(fn -> letter(player1) end)
    player2 = spawn(fn -> letter(player2) end)

    random_word = choose_random_word("wordlist.txt")
    length = length = String.length(random_word)
    word = String.duplicate("_", length)
    #IO.puts "random word is #{random_word}"

    engine = spawn(fn -> engine(player_id,opponent_id,player1,player2,game_manager_id,random_word,word) end)
    send(engine,{:init})
  end

  def engine(player_id,opponent_id,player1,player2,game_manager_id,random_word,word) do
    receive do
      {:init} ->
        IO.puts "Hello #{player_id} and #{opponent_id} the word you need to guess looks like this : #{word}"
        send(player1,{:play,self(),word})

        {:guess,guessed_letter,source,current_word} ->
          new_word =
          cond do
            check_letter(guessed_letter,random_word,current_word) == "no_match" -> current_word
            true -> check_letter(guessed_letter,random_word,current_word)
          end
          next =
          cond do
            source == player1 -> player2
            source == player2 -> player1
          end
          case new_word == random_word do
            true ->
              send(self(),{:end_game,source})
            _ ->
              send(next,{:play,self(),new_word})
          end

          {:end_game,winner} ->
            cond do
              winner == player1 -> send(game_manager_id,{:endgame,player_id})
              winner == player2 -> send(game_manager_id,{:endgame,opponent_id})
              true -> send(game_manager_id,{:endgame,"no"})
            end
            Process.exit(player1, :normal)
            Process.exit(player2, :normal)
            Process.exit(self(), :normal)
    end
    engine(player_id,opponent_id,player1,player2,game_manager_id,random_word,word)
  end

  def letter(player_id) do
    receive do
      {:play,source,word} ->
        guessed_letter = check_error(player_id)
        send(source,{:guess,guessed_letter,self(),word})
    end
    letter(player_id)
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

  def is_letter(str) do
    String.length(str) == 1 && String.match?(str, ~r/[a-z]/)
  end

  def check_error(player_id) do
    input = IO.gets "#{player_id}, please give me a letter : "
    letter = is_letter(String.downcase(String.trim(input)))
    case letter do
      true ->
        input
      _ ->
        IO.puts "Invalid input, please enter a single letter"
        check_error(player_id)
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
