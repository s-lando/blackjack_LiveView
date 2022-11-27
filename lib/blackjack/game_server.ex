defmodule GameServer do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # read apis
  def get_game_state() do
    GenServer.call(__MODULE__, :get_game_state)
  end

  # call vs cast for updates.  could call, reply with game state, and eliminate calls to get_game_state in handle_info except for mount
  # if we have any syncing issues this may be worth looking into

  # update apis
  def sit(player_id, seat_id) do
    GenServer.cast(__MODULE__, {:sit, player_id, seat_id})
  end

  def hit(seat_id) do
    GenServer.cast(__MODULE__, {:hit, seat_id})
  end

  def stand(seat_id) do
    GenServer.cast(__MODULE__, {:stand, seat_id})
  end

  def leave(seat_id) do
    GenServer.cast(__MODULE__, {:leave, seat_id})
  end

  def dealer_action() do
    GenServer.cast(__MODULE__, :dealer_action)
  end

  def start_round() do
    GenServer.cast(__MODULE__, :start_round)
  end

  @impl true
  def init(nil) do
    game_state = %{
      dealer: [],
      seat1: nil,
      seat2: nil,
      seat3: nil,
      cards: CardServer.get_remaining_deck(),
      game_in_progress: false,
      turn: 0,
      completed_games: 0
    }

    {:ok, game_state}
  end

  @impl true
  def handle_call(:get_game_state, _from, state) do
    {:reply, state, state}
  end

  # seat id is an atom e.g. :seat1
  @impl true
  def handle_cast({:sit, player_id, seat_id}, state) do
    player = %{
      playerID: player_id,
      hand: [],
      hand_value: 0,
      hand_value_option2: %{}
    }

    Logger.info("player_id: #{player_id}, and seat_id #{seat_id}")
    {:noreply, Map.put(state, seat_id, player)}
  end

  @impl true
  def handle_cast(:start_round, state) do
    new_state =
      state
      |> Map.put(:game_in_progress, true)
      # new deck / shuffle deck?
      # consider dealing in order of seat1, seat2, seat3, dealer, one card at at time
      |> Map.put(:dealer, CardServer.deal(2))
      |> Map.put(:turn, 1)
      |> update_seated_player_state(:seat1)
      |> update_seated_player_state(:seat2)
      |> update_seated_player_state(:seat3)
      |> Map.put(:cards, CardServer.get_remaining_deck())

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:hit, seat_id}, state) do
    player = Map.get(state, seat_id)
    new_card = CardServer.deal()
    new_hand = player.hand ++ new_card
    player_state = Map.put(player, :hand, new_hand)

    if get_value_of_hand(new_hand).option_1 > 21 do
      player_state = Map.put(player_state, :hand_value, :bust)

      new_state =
        state
        |> Map.put(seat_id, player_state)
        |> Map.put(:turn, state.turn + 1)

      {:noreply, new_state}
    else
      # do we use hand_value or just hand_value_option2?
      player_state = Map.put(player_state, :hand_value_option2, get_value_of_hand(new_hand))

      new_state = Map.put(state, seat_id, player_state)

      {:noreply, new_state}
    end
  end

  defp update_seated_player_state(game_state, seatId) do
    cards_dealt = CardServer.deal(2)

    case Map.get(game_state, seatId) do
      nil ->
        game_state

      %{:hand => existing_hand} = player ->
        updated_hand = existing_hand ++ cards_dealt

        p =
          player
          |> Map.put(:hand, updated_hand)
          |> Map.put(:hand_value_option2, get_value_of_hand(updated_hand))

        Map.put(game_state, seatId, p)
    end
  end

  # source this function from:
  # https://github.com/dorilla/live_view_black_jack/blob/master/lib/black_jack_web/game_manager/manager.ex
  # @returns: a map of 2 value options based on card combo: %{option_1: int, option_2: int}
  def get_value_of_hand(hand) do
    Enum.reduce(hand, %{option_1: 0, option_2: 0}, fn card, acc ->
      %{option_1: acc1, option_2: acc2} = acc
      %{option_1: get_value_of_card(card) + acc1, option_2: get_value_of_card(card, true) + acc2}
    end)
  end

  def get_value_of_card({rank, _suit}, ace_2 \\ false) do
    case is_atom(rank) do
      true ->
        case rank do
          :ace -> if ace_2, do: 11, else: 1
          :jack -> 10
          :queen -> 10
          :king -> 10
        end

      false ->
        rank
    end
  end
end
