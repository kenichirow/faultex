defmodule Faultex.InjectorTest do
  use ExUnit.Case

  describe "Faultex.inject/1 dispatch" do
    test "dispatches FaultInjector correctly" do
      injector = %Faultex.Injector.FaultInjector{
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

  describe "FaultInjector.inject/1" do
    test "returns Response with configured values" do
      injector = %Faultex.Injector.FaultInjector{
        resp_status: 403,
        resp_headers: [{"x-reason", "forbidden"}],
        resp_body: "forbidden"
      }

      resp = Faultex.Injector.FaultInjector.inject(injector)
      assert resp.status == 403
      assert resp.headers == [{"x-reason", "forbidden"}]
      assert resp.body == "forbidden"
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
end
