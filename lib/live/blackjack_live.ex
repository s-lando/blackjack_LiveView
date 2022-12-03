defmodule BlackjackWeb.BlackjackLive do
  use BlackjackWeb, :live_view
  require Logger

  @impl true
  def mount(params, _session, socket) do
    Logger.info("Mounted view")
    # subscribes all users to the game_state topic so that
    # I can handle_info for different events received from broadcast
    if connected?(socket),
      do: BlackjackWeb.Endpoint.subscribe("game_state")

    game_state = GameServer.get_game_state()

    {:ok,
     assign(socket,
       playerID: params["name"],
       playerName: params["name"],
       result: nil,
       game_state: game_state
     )}
  end

  @impl true
  def handle_event("hit", %{"seatid" => seat_id}, socket) do
    GameServer.hit(String.to_atom(seat_id))
    BlackjackWeb.Endpoint.broadcast("game_state", "game_state_change", :game_state_change)
    {:noreply, socket}
  end

  @impl true
  def handle_event("stand", %{"seatid" => seat_id}, socket) do
    GameServer.stand(String.to_atom(seat_id))
    BlackjackWeb.Endpoint.broadcast("game_state", "game_state_change", :game_state_change)
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, result: nil)}
  end

  @impl true
  def handle_event("close_restart_round", _params, socket) do
    GameServer.start_round()
    BlackjackWeb.Endpoint.broadcast("game_state", "game_state_change", :game_state_change)
    {:noreply, assign(socket, result: nil)}
  end

  @impl true
  def handle_event("seat", %{"seatid" => seat_id}, socket) do
    if (socket.assigns.game_state.seat1 != nil &&
          socket.assigns.game_state.seat1.playerID == socket.assigns.playerID) ||
         (socket.assigns.game_state.seat2 != nil &&
            socket.assigns.game_state.seat2.playerID == socket.assigns.playerID) ||
         (socket.assigns.game_state.seat3 != nil &&
            socket.assigns.game_state.seat3.playerID == socket.assigns.playerID) do
      {:noreply, socket}
    else
      IO.puts("this is the player id: " <> inspect(socket.assigns.playerID))
      IO.puts("This is the current seat1: " <> inspect(socket.assigns.game_state.seat1))
      IO.puts("This is the current seat2: " <> inspect(socket.assigns.game_state.seat2))
      GameServer.sit(socket.assigns.playerID, String.to_atom(seat_id))
      BlackjackWeb.Endpoint.broadcast("game_state", "game_state_change", :game_state_change)
      {:noreply, assign(socket, seat: String.to_atom(seat_id))}
    end
  end

  @impl true
  def handle_event("leave_seat", _params, socket) do
    GameServer.leave(socket.assigns.playerID, socket.assigns.seat)
    BlackjackWeb.Endpoint.broadcast("game_state", "user_leaving_game", socket.assigns.seat)
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_round", _params, socket) do
    GameServer.start_round()
    BlackjackWeb.Endpoint.broadcast("game_state", "game_state_change", :game_state_change)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "game_state_change", payload: _}, socket) do
    Logger.info("game state updated")
    game_state_new = GameServer.get_game_state()
    current_turn = Map.get(game_state_new, :turn)
    total_players = Map.get(game_state_new, :total_players)

    Logger.info("Current turn: #{current_turn}, Total players: #{total_players}")

    player_result = Map.get(game_state_new, socket.assigns.seat) |> Map.get(:result)

    case current_turn == -1 do
      true ->
        case game_state_new.game_in_progress do
          true ->
            GameServer.dealer_action()

            BlackjackWeb.Endpoint.broadcast!(
              "game_state",
              "game_state_change",
              :game_state_change
            )

            {:noreply,
             assign(socket, result: player_result, game_state: GameServer.get_game_state())}

          false ->
            BlackjackWeb.Endpoint.broadcast("game_state", "game_ended", game_state_new)
        end

      false ->
        {:noreply, assign(socket, result: player_result, game_state: game_state_new)}
    end

    {:noreply, assign(socket, result: player_result, game_state: game_state_new)}
  end

  @impl true
  def handle_info(%{event: "game_ended", payload: new_game_state}, socket) do
    Logger.info("Game has ended")
    Logger.info("Game state")
    Logger.info(new_game_state)
    player_seat = socket.assigns.seat
    result = Map.get(new_game_state, player_seat) |> Map.get(:result)
    {:noreply, assign(socket, result: result, game_state: new_game_state)}
  end

  def handle_info(%{event: "user_leaving_game", payload: _}, socket) do
    {:noreply, assign(socket, result: nil, seat: nil, game_state: GameServer.get_game_state())}
  end

  @impl true
  def terminate({:shutdown, :closed}, socket) do
    Logger.info(socket.assigns.playerID)

    case Map.get(socket.assigns, :seat) do
      nil ->
        {:noreply, socket}

      seat_id ->
        GameServer.leave(seat_id, socket.assigns.playerID)
        BlackjackWeb.Endpoint.broadcast("game_state", "user_leaving_game", socket.assigns.seat)
    end
  end

  def terminate(reason, _socket) do
    Logger.info(reason)
    Logger.info("another terminate handle")
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
