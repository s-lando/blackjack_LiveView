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

  # update apis
  def sit(player_id, seat_id) do
    GenServer.cast(__MODULE__, {:sit, player_id, seat_id})
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
      cards: CardServer.get_remaining_deck,
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
      hand_value: 0
    }
    Logger.info("player_id: #{player_id}, and seat_id #{seat_id}")
    {:noreply, Map.put(state, seat_id, player)}
  end

  @impl true
  def handle_cast(:start_round, state) do
    {:noreply, state}
  end

end
