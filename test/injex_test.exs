defmodule InjexTest do
  use ExUnit.Case
  doctest Injex

  test "When request to Plug are matches Injex.Mathers, It must return error" do
    conn = Plug.Test.conn("POST", "das/auth/testapp/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-fault-inject", "auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = Injex.Plug.call(conn, Injex.Plug.init([]))
    assert conn.status == 401
  end

  test "Request to remote server" do
    {:ok, res} = Injex.HTTPoison.get("https://github.com/", [])
    assert res.status_code == 200

    #  {:ok, res} = Injex.HTTPoison.get("https://github.com/foo", [])
    #  assert res.status_code == 404

    {:ok, res} = Injex.HTTPoison.get("https://github.com/foo", [{"x-fault-inject", "github"}])

    assert res.status_code == 400
  end
end
