defmodule Faultex.PlugTest do
  use ExUnit.Case

  defmodule HostMatchRouter do
    use Faultex.Plug,
      injectors: [
        %{
          host: "www.example.com",
          path: "/api/*path",
          method: "GET",
          percentage: 100,
          resp_headers: [],
          resp_status: 503,
          resp_body: "service unavailable"
        }
      ]

    plug(:match)
    plug(:dispatch)

    get "/api/health" do
      send_resp(conn, 200, "ok")
    end
  end

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

  test "host マッチ: 一致する host のリクエストは injector がマッチする" do
    conn = Plug.Test.conn("GET", "/api/health")
    conn = HostMatchRouter.call(conn, HostMatchRouter.init(matcher: HostMatchRouter))
    assert conn.status == 503
  end

  test "host マッチ: 一致しない host のリクエストはスルーされる" do
    conn = Plug.Test.conn("GET", "/api/health")
    conn = %{conn | host: "other.example.com"}
    conn = HostMatchRouter.call(conn, HostMatchRouter.init(matcher: HostMatchRouter))
    assert conn.status == 200
  end

  test "Faultex.Plug" do
    conn = Plug.Test.conn("POST", "/auth/test/register")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = MyRouter.call(conn, MyRouter.init(matcher: MyRouter))
    assert conn.status == 200

    conn = Plug.Test.conn("POST", "/auth/test/register")
    conn = Plug.Conn.put_req_header(conn, "x-fault-inject", "auth-failed")
    conn = Plug.Conn.put_req_header(conn, "content-type", "application/json")
    conn = MyRouter.call(conn, MyRouter.init(matcher: MyRouter))
    assert conn.status == 401
  end
end
