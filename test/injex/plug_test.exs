defmodule Injex.PlugTest do
  use ExUnit.Case

  test "When request to Plug are matches Injex.Mathers, It must return error" do
    conn = Plug.Test.conn("POST", "/auth/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-fault-inject", "auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = Injex.Plug.call(conn, Injex.Plug.init([]))
    assert conn.status == 401
  end
end
