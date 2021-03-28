defmodule InjexTest do
  use ExUnit.Case
  doctest Injex

  test "receive client request. return 401." do
    conn = Plug.Test.conn("POST", "das/auth/testapp/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-nativebase-fault-inject", "das-auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = Injex.Plug.call(conn, Injex.Plug.init([]))
    assert conn.status == 401
  end

  test "request to remote server. return 400." do
    {:ok, res} = Injex.HTTPoison.get("https://github.com/", [])
    assert res.status_code == 200
    {:ok, res} = Injex.HTTPoison.get("https://github.com/das/foo", [])
    assert res.status_code == 404

    {:ok, res} =
      Injex.HTTPoison.get("https://github.com/das/foo", [{"x-nativebase-fault-inject", "github"}])

    assert res.status_code == 400
  end
end
