defmodule GameServer do
  @moduledoc """
  A non-registered Cards server using GenServer
  """

  @doc """
  Generic Card server that allows multiple servers to be spin up
  Here are the client api
  - count(pid): provides count of current number of cards handled by the server
  - new(pid): creates a new card deck for the server
  - deal(pid, n \\ 1):
  """
  use GenServer

  # client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, create_deck(), name: __MODULE__)
  end

  def count() do
    GenServer.call(__MODULE__, :count)
  end

  def deal(n \\ 1) do
    GenServer.call(__MODULE__, {:deal, n})
  end

  def get_remaining_deck() do
    GenServer.call(__MODULE__, :get)
  end

  def new() do
    GenServer.cast(__MODULE__, :new)
  end

  def stop(reason) do
    GenServer.stop(__MODULE__, reason)
  end

  # server side implementation
  @impl true
  def init(deck) do
    # when initializing the card server, first check if
    # our database server has data? If null, then we'll create the deck manually
    # if Cards.Store server get returns data, then start our Card server with that
    IO.puts("Server started")
    {:ok, deck}
  end


   # for a handle_cast call, the second parameter is the state since
  # we don't need to send a reply back to client
  @impl true
  def handle_cast(:new, _state) do
    # because we are updating the state here, we need to write to Cards.Store
    deck = create_deck()
    {:noreply, deck}
  end

  @impl true
  def handle_call(:get, _from, deck) do
    {:reply, deck, deck}
  end

  @impl true
  def handle_call(:count, _from, state) do
    {:reply, state |> Enum.count, state}
  end

  # notes for self: handle_call's body reply's second argument is what's being sent
  # back to client, the third argument is the state in case anything is changed to the state
  @impl true
  def handle_call({:deal, n}, _from, state) do
    cond do
      is_number(n) == false -> {:reply, {:ok, []}, state}
      n <= 0 -> {:reply, {:ok, []}, state}
      n > Enum.count(state) ->
        # We don't want the deck to be depleted so will add to the deck with a new one
        # when the card count is less than what user asks for
        new_deck = state ++ create_deck()
        BlackjackWeb.Endpoint.broadcast("game_state", "testing", "added new deck to cards")
        deal_cards(new_deck, n)
      true -> deal_cards(state, n)
    end
  end

  @impl true
  # this callback is called when GenServer.stop is called for the server
  def terminate(reason, state) do
    IO.puts("from terminate inside cards server")
    IO.puts("#{inspect(reason)}")
    {:noreply, state}
  end

  defp create_deck do
    suites = [:spade, :heart, :diamond, :club]
    l1 = for x <- 2..10, do: x
    l2 = [:jack, :king, :queen, :ace]
    values = l1 ++ l2
    deck = for v <- values, s <- suites, do: {v, s}
    Enum.shuffle(deck)
  end

  defp deal_cards(current_deck, number_of_cards) do
    {dealt_deck, updated_deck} = Enum.split(current_deck, number_of_cards)
    {:reply, {:ok, dealt_deck}, updated_deck}
  end
end
