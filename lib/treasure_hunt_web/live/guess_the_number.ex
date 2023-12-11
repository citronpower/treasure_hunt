defmodule TreasureHuntWeb.GuessTheNumber do
  use TreasureHuntWeb, :live_view

  @topic "GuessTheNumberManager"

  def mount(_params, session, socket) do
    id = 123
    TreasureHuntWeb.Endpoint.subscribe(@topic <> id)

    {:ok, socket}
  end

## OVERWRITED BY light_live.html.heex
#  def render(assigns) do
#    ~L"""
#    <h1>The light is <%= @player %>.</h1>
#    """
#  end

  def handle_event("join", value, socket) do

    {:noreply, assign(socket, %{})}
  end

  def handle_event("challenge", value, socket) do
    {:noreply, assign(socket, %{})}
  end

  def handle_info(msg, socket) do
    IO.puts("MESSAGES")
    {:noreply, socket}
  end
end