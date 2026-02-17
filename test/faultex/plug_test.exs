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

  defmodule RandomRouter do
    use Faultex.Plug,
      injectors: [
        %Faultex.Injector.RandomInjector{
          path: "/random",
          method: "GET",
          percentage: 100,
          injectors: [
            %Faultex.Injector.ErrorInjector{resp_status: 500, resp_body: "500"},
            %Faultex.Injector.ErrorInjector{resp_status: 503, resp_body: "503"}
          ]
        }
      ]

    plug(:match)
    plug(:dispatch)

    get "/random" do
      send_resp(conn, 200, "ok")
    end

    post "/random" do
      send_resp(conn, 200, "ok")
    end
  end

  defmodule ChainRouter do
    use Faultex.Plug,
      injectors: [
        %Faultex.Injector.ChainInjector{
          path: "/chain",
          method: "GET",
          percentage: 100,
          injectors: [
            %Faultex.Injector.SlowInjector{resp_delay: 50},
            %Faultex.Injector.ErrorInjector{resp_status: 503, resp_body: "timeout"}
          ]
        }
      ]

    plug(:match)
    plug(:dispatch)

    get "/chain" do
      send_resp(conn, 200, "ok")
    end

    post "/chain" do
      send_resp(conn, 200, "ok")
    end
  end

  describe "RandomInjector" do
    test "returns one of the configured error responses when matched" do
      conn = Plug.Test.conn("GET", "/random")
      conn = RandomRouter.call(conn, RandomRouter.init(matcher: RandomRouter))
      assert conn.status in [500, 503]
    end

    test "returns normal response when not matched" do
      conn = Plug.Test.conn("POST", "/random")
      conn = RandomRouter.call(conn, RandomRouter.init(matcher: RandomRouter))
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end
  end

  describe "ChainInjector" do
    test "applies delay and returns error response when matched" do
      conn = Plug.Test.conn("GET", "/chain")
      start = System.monotonic_time(:millisecond)
      conn = ChainRouter.call(conn, ChainRouter.init(matcher: ChainRouter))
      elapsed = System.monotonic_time(:millisecond) - start

      assert conn.status == 503
      assert conn.resp_body == "timeout"
      assert elapsed >= 50
    end

    test "returns normal response when not matched" do
      conn = Plug.Test.conn("POST", "/chain")
      conn = ChainRouter.call(conn, ChainRouter.init(matcher: ChainRouter))
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end
  end

  defmodule StealRouter do
    use Faultex.Plug,
      injectors: [
        %Faultex.Injector.StealResponseInjector{path: "/steal", method: "GET", percentage: 100}
      ]

    plug(:match)
    plug(:dispatch)

    get "/steal" do
      send_resp(conn, 200, "ok")
    end

    post "/steal" do
      send_resp(conn, 200, "ok")
    end
  end

  describe "StealResponseInjector" do
    test "kills process before response is sent when matched" do
      conn = Plug.Test.conn("GET", "/steal")
      opts = StealRouter.init(matcher: StealRouter)

      pid =
        spawn(fn ->
          StealRouter.call(conn, opts)
        end)

      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}, 1000
    end

    test "returns normal response when not matched" do
      conn = Plug.Test.conn("POST", "/steal")
      conn = StealRouter.call(conn, StealRouter.init(matcher: StealRouter))
      assert conn.status == 200
    end
  end

  describe "RejectInjector" do
    test "halts without sending response when matched" do
      conn = Plug.Test.conn("GET", "/reject")
      conn = RejectRouter.call(conn, RejectRouter.init(matcher: RejectRouter))
      assert conn.halted
      assert conn.state == :unset
    end

    test "returns normal response when not matched" do
      conn = Plug.Test.conn("POST", "/reject")
      conn = RejectRouter.call(conn, RejectRouter.init(matcher: RejectRouter))
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end
  end
end
