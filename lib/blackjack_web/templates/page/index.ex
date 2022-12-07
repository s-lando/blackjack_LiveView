defmodule BlackjackWeb.Index do
  use BlackjackWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, :username, "")
    {:ok, assign(socket, :username, "")}
  end

  def render(assigns) do
    ~L"""
    <div class="header">
    <h2>Blackjack</h2>
    </div>
    <div class="userInfoFormContainer">
    <div class="enterUserInfoForm">
    <div class="rules"> <h2>How to play?</h2>
    <p>Step 1: Join a Table</p>
    <p>Step 2: Check your Hand Value</p>
    <p>Step 3: Decide whether to Hit or Stand</p>
    <p>Step 4: Dealer Reveals Their Cards</p>
    <p>Step 5: See Who is Closer to 21</p>
    </div>
    <form phx-submit="new">
    <label>Enter your name to start: </label>
    <input placeholder="player_name" name ="username"/>

    <button type="submit"> Enter Game </button>
    </form>
    </div>
    </div>

    """
  end

  def handle_event("new", %{"username" => params}, socket) do
    socket = assign(socket, :username, params)
    url = "/blackjack_live/" <> params
    {:noreply, push_redirect(socket, to: url)}
  end
end
