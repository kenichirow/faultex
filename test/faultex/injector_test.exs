defmodule Faultex.InjectorTest do
  use ExUnit.Case

  describe "Faultex.inject/1 dispatch" do
    test "dispatches ErrorInjector correctly" do
      injector = %Faultex.Injector.ErrorInjector{
        resp_status: 500,
        resp_headers: [{"x-error", "true"}],
        resp_body: "error"
      }

      resp = Faultex.inject(injector)
      assert %Faultex.Response{status: 500, headers: [{"x-error", "true"}], body: "error"} = resp
    end

    test "dispatches SlowInjector correctly" do
      injector = %Faultex.Injector.SlowInjector{}
      resp = Faultex.inject(injector)
      assert %Faultex.Response{} = resp
    end

    test "dispatches RejectInjector correctly" do
      injector = %Faultex.Injector.RejectInjector{}
      resp = Faultex.inject(injector)
      assert %Faultex.Response{headers: [], body: ""} = resp
    end
  end

  describe "ErrorInjector.inject/1" do
    test "returns Response with configured values" do
      injector = %Faultex.Injector.ErrorInjector{
        resp_status: 403,
        resp_headers: [{"x-reason", "forbidden"}],
        resp_body: "forbidden"
      }

      resp = Faultex.Injector.ErrorInjector.inject(injector)
      assert resp.status == 403
      assert resp.headers == [{"x-reason", "forbidden"}]
      assert resp.body == "forbidden"
    end

    test "resp_delay: nil causes no delay" do
      injector = %Faultex.Injector.ErrorInjector{resp_status: 200, resp_delay: nil}
      start = System.monotonic_time(:millisecond)
      _resp = Faultex.Injector.ErrorInjector.inject(injector)
      assert System.monotonic_time(:millisecond) - start < 50
    end

    test "resp_delay: 0 causes no delay" do
      injector = %Faultex.Injector.ErrorInjector{resp_status: 200, resp_delay: 0}
      start = System.monotonic_time(:millisecond)
      _resp = Faultex.Injector.ErrorInjector.inject(injector)
      assert System.monotonic_time(:millisecond) - start < 50
    end

    test "resp_delay: positive value delays by specified milliseconds" do
      injector = %Faultex.Injector.ErrorInjector{resp_status: 200, resp_delay: 50}
      start = System.monotonic_time(:millisecond)
      _resp = Faultex.Injector.ErrorInjector.inject(injector)
      assert System.monotonic_time(:millisecond) - start >= 50
    end
  end

  describe "SlowInjector.inject/1" do
    test "returns empty Response" do
      resp = Faultex.Injector.SlowInjector.inject(%Faultex.Injector.SlowInjector{})
      assert %Faultex.Response{status: nil, headers: nil, body: nil} = resp
    end
  end

  describe "RejectInjector.inject/1" do
    test "returns Response with empty body and headers" do
      resp = Faultex.Injector.RejectInjector.inject(%Faultex.Injector.RejectInjector{})
      assert resp.headers == []
      assert resp.body == ""
    end
  end

  describe "RandomInjector.inject/1" do
    test "dispatches RandomInjector correctly" do
      injector = %Faultex.Injector.RandomInjector{
        injectors: [
          %Faultex.Injector.ErrorInjector{resp_status: 500, resp_body: "error"}
        ]
      }

      resp = Faultex.inject(injector)
      assert resp.status == 500
      assert resp.body == "error"
    end

    test "randomly selects from injectors" do
      :rand.seed(:exsss, {1, 2, 3})

      injector = %Faultex.Injector.RandomInjector{
        injectors: [
          %Faultex.Injector.ErrorInjector{resp_status: 500, resp_body: "500"},
          %Faultex.Injector.ErrorInjector{resp_status: 503, resp_body: "503"}
        ]
      }

      results = for _ <- 1..20, do: Faultex.Injector.RandomInjector.inject(injector).status
      assert 500 in results
      assert 503 in results
    end
  end

  describe "ChainInjector.inject/1" do
    test "dispatches ChainInjector correctly" do
      injector = %Faultex.Injector.ChainInjector{
        injectors: [
          %Faultex.Injector.ErrorInjector{resp_status: 503, resp_body: "timeout"}
        ]
      }

      resp = Faultex.inject(injector)
      assert resp.status == 503
      assert resp.body == "timeout"
    end

    test "executes all injectors and returns last response" do
      injector = %Faultex.Injector.ChainInjector{
        injectors: [
          %Faultex.Injector.ErrorInjector{resp_status: 500, resp_body: "first"},
          %Faultex.Injector.ErrorInjector{resp_status: 503, resp_body: "last"}
        ]
      }

      resp = Faultex.Injector.ChainInjector.inject(injector)
      assert resp.status == 503
      assert resp.body == "last"
    end

    test "SlowInjector + ErrorInjector chain applies delay then returns error" do
      injector = %Faultex.Injector.ChainInjector{
        injectors: [
          %Faultex.Injector.SlowInjector{resp_delay: 50},
          %Faultex.Injector.ErrorInjector{resp_status: 503, resp_body: "timeout"}
        ]
      }

      start = System.monotonic_time(:millisecond)
      resp = Faultex.Injector.ChainInjector.inject(injector)
      elapsed = System.monotonic_time(:millisecond) - start

      assert elapsed >= 50
      assert resp.status == 503
      assert resp.body == "timeout"
    end
  end
end
