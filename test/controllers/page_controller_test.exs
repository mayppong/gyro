defmodule GyroWeb.PageControllerTest do
  use GyroWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Arena"
  end
end
