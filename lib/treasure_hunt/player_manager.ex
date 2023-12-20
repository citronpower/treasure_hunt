defmodule TreasureHunt.PlayerManager do
  use Agent

  def start_link(players) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_player(player_name) do
    random_number = :rand.uniform(9000)+1000
    player = %{
      random_number: random_number,
      revealed_digits_count: 0
    }
    Agent.update(__MODULE__, &(Map.put(&1, player_name, player)))
    get_players()
  end

  def get_players do
    Agent.get(__MODULE__, &(&1))
  end

  def get_player(player) do
    Agent.get(__MODULE__, &(Map.get(&1, player)))
  end

  def get_player_random_number(player) do
    player = get_player(player)
    Map.get(player, :random_number)
  end

  def get_player_revealed_digits_count(player) do
    player = get_player(player)
    Map.get(player, :revealed_digits_count)
  end

  defp update_player(player_name, update_fun) do
    Agent.update(__MODULE__, fn players ->
      Map.update(players, player_name, nil, update_fun)
    end)
  end

  def inc_player_revealed_digits_count(player_name) do
    update_player(player_name, fn player ->
      old_count = Map.get(player, :revealed_digits_count, 0)

      new_count = old_count + 1
      updated_player = Map.put(player, :revealed_digits_count, new_count)

      updated_player
    end)
  end

  def player_below_revealed_digits_limit?(player_name) do
      revealed_digits_count = get_player_revealed_digits_count(player_name)
      revealed_digits_count >= 4
  end
end