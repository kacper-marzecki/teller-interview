defmodule TellerWeb.PageControllerTest do
  use TellerWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/accounts")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
