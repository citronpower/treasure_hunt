defmodule TreasureHunt.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  #@players []#%{}

  @impl true
  def start(_type, _args) do
    children = [
      TreasureHuntWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:treasure_hunt, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TreasureHunt.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TreasureHunt.Finch},
      # Start a worker by calling: TreasureHunt.Worker.start_link(arg)
      # {TreasureHunt.Worker, arg},
      # Start to serve requests, typically the last entry
      TreasureHuntWeb.Endpoint,
      {TreasureHunt.PlayerManager, []},
      {TreasureHunt.GameManager, [TreasureHunt.RockPaperScissorsManager, TreasureHunt.GuessTheNumberManager, TreasureHunt.DiceManager, TreasureHunt.HangmanManager]}#, TreasureHunt.DiceManager, TreasureHunt.HangmanManager, TreasureHunt.RockPaperScissorsManager]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TreasureHunt.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TreasureHuntWeb.Endpoint.config_change(changed, removed)
    :ok
  end

#  def get_players() do
#    @players
#  end
#
#  def add_player(player_name) do
#    case player_name in @players do #case Map.get(@players, player_name) do
#      false ->
#        #TreasureHunt.Application.add_player(player_name)
#        IO.puts("I am here")
#        IO.puts(inspect(@players))
#        @players = @players ++ [player_name]
#        IO.puts("New player #{player_name} joined the game!")
#        IO.puts(inspect(@players))
#      true ->
#        IO.puts("Player #{player_name} already exist!")
#    end
#
#  end
end
