defmodule InjexTest do
  use ExUnit.Case
  doctest Injex

  test "greets the world" do
    conn = Plug.Test.conn("POST", "das/auth/testapp/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-nativebase-fault-inject", "das-auth-failed")
    conn = Injex.Plug.call(conn, Injex.Plug.init([]))
    IO.inspect(conn)
  end
end
