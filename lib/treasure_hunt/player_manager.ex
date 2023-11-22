defmodule TreasureHunt.PlayerManager do
  use Agent

  def start_link(players) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_player(player_name) do
    Agent.update(__MODULE__, &(Map.put(&1, player_name, [])))
  end

  def get_players() do
    Agent.get(__MODULE__, &(&1))
  end

  def get_player(player) do
    Agent.get(__MODULE__, &(Map.get(&1, player)))
  end
end