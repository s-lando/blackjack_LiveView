defmodule GameServer do
  use GenServer

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

    player1 = %{
      hand: CardServer.deal(2)
    }

    game_state = %{
      dealer: [],
      seat1: nil,
      seat2: player1,
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

  @impl true
  def handle_cast({:sit, player_id, seat_id}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:start_round, state) do
    {:noreply, state}
  end

end
