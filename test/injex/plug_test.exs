defmodule Injex.PlugTest do
  use ExUnit.Case

  defmodule MyRouter do
    use Injex.Plug,
      injectors: [
        %{
          host: "*",
          path: "/auth/:id/*path",
          method: "POST",
          exact: true,
          headers: [{"x-fault-inject", "auth-failed"}],
          percentage: 100,
          resp_headers: [],
          resp_status: 401,
          resp_body: "{}",
          resp_delay: 1000
        }
      ]

    use Plug.Router
    plug(:dispatch)

    get "/foo" do
    end
  end

  test "When request to Plug are matches Injex.Mathers, It must return error" do
    conn = Plug.Test.conn("POST", "/auth/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-fault-inject", "auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = Injex.Plug.call(conn, Injex.Plug.init([]))
    assert conn.status == 401
  end
end
