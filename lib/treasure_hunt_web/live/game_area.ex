defmodule TreasureHuntWeb.GameArea do
  use TreasureHuntWeb, :live_view

  @topic "gamearea"

#  def load_players(socket, player) do
#    #code = TreasureHunt.PlayerManager.get_player(player_name)
#    players = TreasureHunt.PlayerManager.get_players() |>
#        Map.delete(player)
#
#    IO.puts(inspect(players))
#
#    socket |> assign(:players, players)
##    conn
##        |> put_flash(:info, "Welcome to the treasure hunt #{player_name}!")
##        |> assign(:players, players)
##        |> assign(:player_name, player_name)
##        |> render("index.html")
#  end

  def mount(_params, session, socket) do
    TreasureHuntWeb.Endpoint.subscribe(@topic)

    IO.puts("MOUNT")
    IO.puts(inspect(session))
    IO.puts(Map.get(session, "_csrf_token"))

#    player = fetch_cookies(socket, encrypted: ~w(player)) |> Map.from_struct()
#      |> get_in([:cookies, "player"])
    player = Map.get(session, "_csrf_token")
    players = %{}
    IO.puts(inspect(player))
    if player != nil do
      players = TreasureHunt.PlayerManager.get_players() |>
                                             Map.delete(player)
    end
    socket = socket |>
      assign(:players, players) |>
      assign(:player, player)
    {:ok, socket}
  end

## OVERWRITED BY light_live.html.heex
#  def render(assigns) do
#    ~L"""
#    <h1>The light is <%= @player %>.</h1>
#    """
#  end

  def handle_event("join", value, socket) do
    IO.puts(inspect(value))
    player = Map.get(value, "player")
    IO.puts("JOIN PLAYER:")
    IO.puts(player)
    players = TreasureHunt.PlayerManager.add_player(player) |>
                                             Map.delete(player)
#    IO.puts("TEST")
#    IO.puts(inspect(players))
    state = %{player: player, players: players}
    TreasureHuntWeb.Endpoint.broadcast_from(self(), @topic, "join", state)

    {:noreply, assign(socket, state)}
  end

  def handle_event("challenge", value, socket) do
    IO.puts(inspect(value))
    player = Map.get(value, "player")
    opponent = Map.get(value, "opponent")
    TreasureHunt.GameManager.initiate_challenge(player, opponent)

    {:noreply, assign(socket, %{})}
  end

  def handle_info(msg, socket) do
    IO.puts("MESSAGES")
    IO.puts(inspect(msg))
    socket =
      socket
      |> assign(:players, TreasureHunt.PlayerManager.get_players())
    {:noreply, socket}
  end
end