defmodule GyroWeb.PageController do
  use GyroWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
