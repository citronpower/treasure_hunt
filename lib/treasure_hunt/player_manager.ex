defmodule TreasureHunt.PlayerManager do
  use Agent

  def start_link(players) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_player(player_name) do
    random_number = :rand.uniform(9000) + 1000
    Agent.update(__MODULE__, &(Map.put(&1, player_name, random_number)))
    get_players()
  end

  def get_players() do
    Agent.get(__MODULE__, &(&1))
  end

  def get_player(player) do
    Agent.get(__MODULE__, &(Map.get(&1, player)))
  end


end