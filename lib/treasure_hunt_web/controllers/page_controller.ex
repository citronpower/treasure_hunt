defmodule TreasureHuntWeb.PageController do
  use TreasureHuntWeb, :controller


#  def home(conn, _params) do
#    # The home page is often custom made,
#    # so skip the default app layout.
#    render(conn, :home, layout: false)
#  end
  
#  def index(conn, _params) do
#    render(conn, "index.html")
#  end

  def load_player(conn, player_name) do
    #code = TreasureHunt.PlayerManager.get_player(player_name)
    players = TreasureHunt.PlayerManager.get_players() |>
        Map.delete(player_name)

    IO.puts(inspect(players))
    conn
        |> put_flash(:info, "Welcome to the treasure hunt #{player_name}!")
        |> assign(:players, players)
        |> assign(:player_name, player_name)
        |> render("index.html")
  end

  def join(conn, _params) do
    player = fetch_cookies(conn, encrypted: ~w(player)) |> Map.from_struct()
      |> get_in([:cookies, "player"])

    case player do
      nil ->
        conn
          |> render("join.html")

      player ->
        load_player(conn, Map.get(player, :player_name))
    end
  end

  def register(conn, %{"player_name" => player_name}) do
    players = TreasureHunt.PlayerManager.get_players()#TreasureHunt.Application.get_players()

    if ! player_name in players do
      TreasureHunt.PlayerManager.add_player(player_name) end
    conn

    load_player(conn |>
      put_resp_cookie("player", %{player_name: player_name}, max_age: 36000, encrypt: true),
      player_name)
  end

    #load_player(conn |>
      #put_resp_cookie("player", %{player_name: player_name}, max_age: 3600, encrypt: true),
      #player_name)
 #end
  
#  def show(conn, %{"messenger" => messenger}) do
#	conn
#    |> assign(:messenger, messenger)
#    |> assign(:receiver, "Dweezil")
#    |> render(:show)
#  end

  # Retrieve Player's ID 
#  defp get_player_id_from_conn(conn) do
#    player = fetch_cookies(conn, encrypted: ~w(player)) |> Map.from_struct()
#      |> get_in([:cookies, "player"])

#    case player do 
#      %{"player_name" => player_name} ->
#        player_name
#      _ ->
#        nil
#    end
#  end

  # Choose Game Actions
#   def choose_game(conn, _params) do
#    player_id = get_player_id_from_conn(conn)
#    game_options = TreasureHunt.GameManager.get_game_options()

#    render(conn, "choose_game.html", game_options: game_options)
#  end

end
