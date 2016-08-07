defmodule Gyro.PageControllerTest do
  use Gyro.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Arena"
  end
end
