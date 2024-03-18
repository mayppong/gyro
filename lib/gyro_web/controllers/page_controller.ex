defmodule GyroWeb.PageController do
  use GyroWeb, :controller

  def index(conn, _params) do
    render(conn, :home)
  end
end
