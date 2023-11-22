defmodule TreasureHunt.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

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
      TreasureHuntWeb.Endpoint
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
end
