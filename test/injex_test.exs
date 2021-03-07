defmodule InjexTest do
  use ExUnit.Case
  doctest Injex

  test "greets the world" do
    conn = Plug.Test.conn("POST", "das/auth/testapp/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-nativebase-fault-inject", "das-auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = Injex.Plug.call(conn, Injex.Plug.init([]))
    assert conn.status == 401
  end
end
