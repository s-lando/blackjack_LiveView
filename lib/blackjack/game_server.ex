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
    GenServer.call(__MODULE__, {:sit, player_id, seat_id})
  end

  def hit(seat_id) do
    GenServer.call(__MODULE__, {:hit, seat_id})
  end

  def stand(seat_id) do
    GenServer.call(__MODULE__, {:stand, seat_id})
  end

  def leave(player_id, seat_id) do
    GenServer.call(__MODULE__, {:leave, seat_id, player_id})
  end

  def dealer_action() do
    GenServer.call(__MODULE__, :dealer_action)
  end

  def start_round() do
    GenServer.call(__MODULE__, :start_round)
  end

  @impl true
  def init(nil) do
    game_state = %{
      dealer: [],
      seat1: nil,
      seat2: nil,
      seat3: nil,
      # cards: CardServer.get_remaining_deck(),
      game_in_progress: false,
      turn: 0,
      completed_games: 0,
      total_players: [],
      dealer_score: 0
    }

    {:ok, game_state}
  end

  @impl true
  def handle_call(:get_game_state, _from, state) do
    {:reply, state, state}
  end

  # seat id is an atom e.g. :seat1
  @impl true
  def handle_call({:sit, player_id, seat_id}, _from, state) do
    player = %{
      playerID: player_id,
      hand: [],
      hand_value: 0,
      hand_options: %{},
      result: nil,
      score: 0
    }

    new_total_player = Map.get(state, :total_players)
    new_total_player = [player_id | new_total_player]

    new_state =
      state
      |> Map.put(seat_id, player)
      |> Map.put(:total_players, new_total_player)

    Logger.info("------------")
    Logger.info(Map.get(state, :total_players))
    Logger.info("------------")

    Logger.info("player_id: #{player_id}, and seat_id #{seat_id}")
    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call(:start_round, _from, state) do
    turn = determine_turn(state, 0)

    CardServer.new()

    new_state =
      state
      |> Map.put(:game_in_progress, true)
      # new deck / shuffle deck?
      # consider dealing in order of seat1, seat2, seat3, dealer, one card at at time
      |> Map.put(:dealer, CardServer.deal(2))
      |> Map.put(:turn, turn)
      |> update_seated_player_state(:seat1)
      |> update_seated_player_state(:seat2)
      |> update_seated_player_state(:seat3)

    # |> Map.put(:cards, CardServer.get_remaining_deck())

    {:reply, new_state, new_state}
  end

  @impl true
  def handle_call({:hit, seat_id}, _from, state) do
    player = Map.get(state, seat_id)
    new_card = CardServer.deal()
    new_hand = player.hand ++ new_card
    player_state = Map.put(player, :hand, new_hand)

    if get_value_of_hand(new_hand).option_1 > 21 do
      player_state = Map.put(player_state, :result, :bust)

      new_state =
        state
        |> Map.put(seat_id, player_state)
        |> Map.put(:turn, determine_turn(state, state.turn))

      {:reply, new_state, new_state}
    else
      # do we use hand_value or just hand_options?
      player_state = Map.put(player_state, :hand_options, get_value_of_hand(new_hand))

      new_state = Map.put(state, seat_id, player_state)

      {:reply, new_state, new_state}
    end
  end

  @impl true
  def handle_call({:stand, _seat_id}, _from, state) do
    new_state =
      state
      |> Map.put(:turn, determine_turn(state, state.turn))

    {:reply, new_state, new_state}
  end

  ## after player turns, would be called repeatedly until game is over
  ## (maybe every once every second?), rerendering for each card dealt
  @impl true
  def handle_call(:dealer_action, _from, state) do
    dealer_hand_value = state.dealer |> best_hand_option()

    if dealer_hand_value >= 17 do
      new_state =
        state
        |> Map.put(:game_in_progress, false)
        |> Map.put(:completed_games, state.completed_games + 1)
        # update each player results
        ## how to do this dynamically??
        |> Map.put(:seat1, update_player_result(state.seat1, dealer_hand_value))
        |> Map.put(:seat2, update_player_result(state.seat2, dealer_hand_value))
        |> Map.put(:seat3, update_player_result(state.seat3, dealer_hand_value))

      newest_state =
        new_state
        |> Map.put(
          :dealer_score,
          update_dealer_result(
            state.dealer_score,
            new_state.seat1,
            new_state.seat2,
            new_state.seat3
          )
        )

      # newest_state |> inspect() |> Logger.debug()
      {:reply, newest_state, newest_state}
    else
      new_state = Map.put(state, :dealer, state.dealer ++ CardServer.deal())

      # new_state |> inspect() |> Logger.debug()
      {:reply, new_state, new_state}
    end
  end

  @impl true
  def handle_call({:leave, seat_id, player_id}, _from, state) do
    current_total_players = Map.get(state, :total_players)
    new = List.delete(current_total_players, player_id)
    # Logger.info("Player left: #{player_id}")
    # Logger.info("Seat left #{seat_id}")
    # Logger.info("new_state: #{new}")

    new_state =
      state
      |> Map.put(seat_id, nil)
      |> Map.put(:total_players, new)

    # Logger.info("kkkkkkkkkkk")
    # Logger.info(Map.get(state, :total_players))
    # Logger.info("kkkkkkkkkkk")
    {:reply, new_state, new_state}
  end

  def update_player_result(player, dealer_hand_value) do
    case player do
      nil ->
        player

      _ ->
        player_hand_value = player.hand |> best_hand_option()

        cond do
          player_hand_value > 21 ->
            # bust already handled in hit
            player

          player_hand_value == 21 && player.hand |> Enum.count() == 2 ->
            new_score = Map.get(player, :score)
            player = Map.put(player, :score, new_score + 1)
            Map.put(player, :result, :blackjack)

          ## if dealer busts, everyone else who didn't bust wins
          dealer_hand_value > 21 ->
            new_score = Map.get(player, :score)
            player = Map.put(player, :score, new_score + 1)
            Map.put(player, :result, :win)

          player_hand_value == dealer_hand_value ->
            Map.put(player, :result, :push)

          # additional path for extra animations on blackjack

          player_hand_value > dealer_hand_value ->
            new_score = Map.get(player, :score)
            player = Map.put(player, :score, new_score + 1)
            Map.put(player, :result, :win)

          player_hand_value < dealer_hand_value ->
            Map.put(player, :result, :lose)

          true ->
            Map.put(player, :result, nil)
        end
    end
  end

  def update_dealer_result(dealerScore, seat1, seat2, seat3) do
    result1 =
      if seat1 == nil do
        nil
      else
        Map.get(seat1, :result)
      end

    result2 =
      if seat2 == nil do
        nil
      else
        Map.get(seat2, :result)
      end

    result3 =
      if seat3 == nil do
        nil
      else
        Map.get(seat3, :result)
      end

    case {result1, result2, result3} do
      {:win, _, _} -> dealerScore
      {_, :win, _} -> dealerScore
      {_, _, :win} -> dealerScore
      {:push, _, _} -> dealerScore
      {_, :push, _} -> dealerScore
      {_, _, :push} -> dealerScore
      {_, _, _} -> dealerScore + 1
    end
  end

  def best_hand_option(hand) do
    hand_value = get_value_of_hand(hand)

    if hand_value.option_2 > 21 do
      hand_value.option_1
    else
      hand_value.option_2
    end
  end

  # returns the int for which seat's turn it is
  def determine_turn(game_state, prev_turn) do
    turn_atom = "seat#{prev_turn + 1}" |> String.to_atom()

    # if :seat{x} is nil, then a player hasn't sat there yet.  if not in map, then we've gone through all seats
    case Map.get(game_state, turn_atom, :noseat) do
      nil ->
        determine_turn(game_state, prev_turn + 1)

      :noseat ->
        -1

      _ ->
        prev_turn + 1
    end
  end

  defp update_seated_player_state(game_state, seatId) do
    hand = CardServer.deal(2)

    case Map.get(game_state, seatId) do
      nil ->
        game_state

      player ->
        p =
          player
          |> Map.put(:hand, hand)
          |> Map.put(:hand_options, get_value_of_hand(hand))
          |> Map.put(:result, nil)

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
