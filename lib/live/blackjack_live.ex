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

    {:ok, assign(socket, player_id: socket.id , game_state: game_state)}
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
  def handle_event("seat", params, socket) do
    player_id = "need to get this value from the frontend"
    GameServer.sit(socket.assigns.player_id, player_id)
    BlackjackWeb.Endpoint.broadcast()
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_seat", params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_game", params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(:game_state_change, socket) do
    {:noreply, assign(socket, game_state: GameServer.get_game_state)}
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
