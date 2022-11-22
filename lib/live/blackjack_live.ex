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

    {:ok, cards} = GameServer.deal(2)
    {:ok, assign(socket, cards: cards)}
  end

  @impl true
  def handle_event("test_click", _value, socket) do
    existing_cards = socket.assigns.cards
    {:ok, new_cards} = GameServer.deal(2)
    {:noreply, assign(socket, cards: existing_cards ++ new_cards)}
  end

  @impl true
  def handle_info(%{event: "testing", payload: message}, socket) do
    Logger.info("Received #{message} from GameServer broadcast")
    {:noreply, assign(socket, cards: [])}
  end

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
