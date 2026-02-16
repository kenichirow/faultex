defmodule Faultex.PlugTest do
  use ExUnit.Case

  defmodule SlowRouter do
    use Faultex.Plug,
      injectors: [
        %Faultex.Injector.SlowInjector{path: "/slow", method: "GET", percentage: 100, resp_delay: 50}
      ]

    plug(:match)
    plug(:dispatch)

    get "/slow" do
      send_resp(conn, 200, "ok")
    end

    post "/slow" do
      send_resp(conn, 200, "ok")
    end
  end

  defmodule RejectRouter do
    use Faultex.Plug,
      injectors: [
        %Faultex.Injector.RejectInjector{path: "/reject", method: "GET", percentage: 100}
      ]

    plug(:match)
    plug(:dispatch)

    get "/reject" do
      send_resp(conn, 200, "ok")
    end

    post "/reject" do
      send_resp(conn, 200, "ok")
    end
  end

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

  test "matches injector when host matches" do
    conn = Plug.Test.conn("GET", "/api/health")
    conn = HostMatchRouter.call(conn, HostMatchRouter.init(matcher: HostMatchRouter))
    assert conn.status == 503
  end

  test "passes through when host does not match" do
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

  describe "SlowInjector" do
    test "does not halt and returns normal handler response when matched" do
      conn = Plug.Test.conn("GET", "/slow")
      conn = SlowRouter.call(conn, SlowRouter.init(matcher: SlowRouter))
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end

    test "delays by resp_delay milliseconds when matched" do
      conn = Plug.Test.conn("GET", "/slow")
      start = System.monotonic_time(:millisecond)
      _conn = SlowRouter.call(conn, SlowRouter.init(matcher: SlowRouter))
      elapsed = System.monotonic_time(:millisecond) - start
      assert elapsed >= 50
    end

    test "returns normal response without delay when not matched" do
      conn = Plug.Test.conn("POST", "/slow")
      start = System.monotonic_time(:millisecond)
      conn = SlowRouter.call(conn, SlowRouter.init(matcher: SlowRouter))
      elapsed = System.monotonic_time(:millisecond) - start
      assert conn.status == 200
      assert elapsed < 50
    end
  end

  describe "RejectInjector" do
    test "raises FunctionClauseError due to nil status when matched" do
      conn = Plug.Test.conn("GET", "/reject")

      assert_raise FunctionClauseError, fn ->
        RejectRouter.call(conn, RejectRouter.init(matcher: RejectRouter))
      end
    end

    test "returns normal response when not matched" do
      conn = Plug.Test.conn("POST", "/reject")
      conn = RejectRouter.call(conn, RejectRouter.init(matcher: RejectRouter))
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end
  end
end
