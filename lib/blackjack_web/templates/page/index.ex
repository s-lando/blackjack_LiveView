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
    <br>
    <br>
    <form phx-submit="new">
    <label>Enter your name to join a table: </label>
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
