defmodule Faultex.PlugTest do
  use ExUnit.Case

  defmodule MyRouter do
    use Faultex.Plug,
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
          resp_body: "unauthorized",
          resp_delay: 1000
        }
      ]

    plug(:match)
    plug(:dispatch)

    post "/auth/test/register" do
      send_resp(conn, 200, "ok")
    end
  end

  test "Faultex.Plug" do
    conn = Plug.Test.conn("POST", "/auth/test/register")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = MyRouter.call(conn, MyRouter.init(matcher: MyRouter))
    assert conn.status == 200

    conn = Plug.Test.conn("POST", "/auth/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-fault-inject", "auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    assert %Plug.Conn{status: 401, resp_body: "unauthorized"} = MyRouter.call(conn, MyRouter.init(matcher: MyRouter))
  end
end
