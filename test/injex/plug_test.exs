defmodule Injex.PlugTest do
  use ExUnit.Case

  defmodule MyRouter do
    use Plug.Router
    plug(:match)
    plug(:dispatch)

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
          resp_body: "YOYO",
          resp_delay: 1000
        }
      ]

    post "/auth/test/register" do
      send_resp(conn, 200, "ok")
    end
  end

  test "When request to Plug are matches Injex.Mathers, It must return error" do
    conn = Plug.Test.conn("POST", "/auth/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-fault-inject", "auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = MyRouter.call(conn, MyRouter.init(matcher: MyRouter))
    IO.inspect(conn)
    assert conn.halted
  end
end
