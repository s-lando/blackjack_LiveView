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

  # test only #############################
  @impl true
  def handle_event("test_click", _value, socket) do
    existing_cards = socket.assigns.cards
    {:ok, new_cards} = GameServer.deal(2)
    {:noreply, assign(socket, cards: existing_cards ++ new_cards)}
  end

  # Test only
  @impl true
  def handle_info(%{event: "testing", payload: message}, socket) do
    Logger.info("Received #{message} from GameServer broadcast")
    {:noreply, assign(socket, cards: [])}
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
