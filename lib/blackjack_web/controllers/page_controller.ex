defmodule BlackjackWeb.PageController do
  use BlackjackWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
