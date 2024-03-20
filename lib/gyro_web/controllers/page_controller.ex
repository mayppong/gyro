defmodule GyroWeb.PageController do
  use GyroWeb, :controller

  def home(conn, _params) do
    render(conn, "home.html")
  end
end
