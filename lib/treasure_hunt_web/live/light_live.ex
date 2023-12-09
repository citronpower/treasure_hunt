defmodule TreasureHuntWeb.LightLive do
  use TreasureHuntWeb, :live_view

  @topic "light"

  def mount(_params, _session, socket) do
    TreasureHuntWeb.Endpoint.subscribe(@topic)

    socket =
      socket
      |> assign(:light_bulb_status, "off")
      |> assign(:on_button_status, "")
      |> assign(:off_button_status, "disabled")

    {:ok, socket}
  end

## OVERWRITED BY light_live.html.heex
#  def render(assigns) do
#    ~L"""
#    <h1>The light is <%= @light_bulb_status %>.</h1>
#    <button phx-click="on" <%= @on_button_status %>>On</button>
#    <button phx-click="off" <%= @off_button_status %>>Off</button>
#    """
#  end

  def handle_event("on", _value, socket) do
    IO.puts("ON")
    state = %{light_bulb_status: "on", on_button_status: "disabled", off_button_status: ""}
    TreasureHuntWeb.Endpoint.broadcast_from(self(), @topic, "on", state)

    {:noreply, assign(socket, state)}
  end

  def handle_event("off", _value, socket) do
    IO.puts("OFF")
    state = %{light_bulb_status: "off", on_button_status: "", off_button_status: "disabled"}
    TreasureHuntWeb.Endpoint.broadcast_from(self(), @topic, "off", state)

    {:noreply, assign(socket, state)}
  end

  def handle_info(msg, socket) do
    IO.puts(inspect(msg))
    socket =
      socket
      |> assign(:light_bulb_status, msg.payload.light_bulb_status)
      |> assign(:on_button_status, msg.payload.on_button_status)
      |> assign(:off_button_status, msg.payload.off_button_status)
    {:noreply, socket}
  end
end