defmodule BlackjackWeb.BlackjackLive do
  use BlackjackWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    Logger.info("Mounted view")
    # subscribes all users to the game_state topic so that
    # I can handle_info for different events received from broadcast
    if connected?(socket),
    do: BlackjackWeb.Endpoint.subscribe("game_state")

    game_state = GameServer.get_game_state()

    {:ok, assign(socket, playerID: socket.id , game_state: game_state)}
  end

  @impl true
  def handle_event("hit", params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("stand", params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("seat", %{"seatid" => seat_id}, socket) do
    GameServer.sit(socket.assigns.playerID, String.to_atom(seat_id))
    BlackjackWeb.Endpoint.broadcast("game_state", "game_state_change", :game_state_change)
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_seat", params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_round", params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "game_state_change", payload: _}, socket) do
    Logger.info("game state updated")
    game_state_new = GameServer.get_game_state()
    Logger.info(game_state_new)
    {:noreply, assign(socket, game_state: game_state_new)}
  end

  @impl true
  def terminate(reason, socket) do
    Logger.info("#{inspect(reason)}")
    Logger.info(socket.assigns.playerID)
    # When a user disconnects, they should automatically call GameServer.leave
    # api - to add this once api is available
  end

  # helper functions to render to view
  defp rank_to_string(rank) do
    case rank do
      :ace -> "a"
      2 -> "2"
      3 -> "3"
      4 -> "4"
      5 -> "5"
      6 -> "6"
      7 -> "7"
      8 -> "8"
      9 -> "9"
      10 -> "10"
      :jack -> "j"
      :queen -> "q"
      :king -> "k"
    end
  end

  defp suit_to_string(suit) do
    case suit do
      :heart -> "hearts"
      :diamond -> "diams"
      :spade -> "spades"
      :club -> "clubs"
    end
  end

end
