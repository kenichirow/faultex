defmodule FaultexTest do
  use ExUnit.Case

  defmodule Matcher do
    use Faultex,
      injectors: [
        %Faultex.Injector.ErrorInjector{
          host: "*",
          path: "/auth/:id/*path",
          method: "POST",
          headers: [{"x-fault-inject", "auth-failed"}],
          percentage: 100,
          resp_headers: [],
          resp_status: 401,
          resp_body: "unauthorized"
        },
        %Faultex.Injector.SlowInjector{
          host: "*",
          path: "/slow",
          method: "GET",
          percentage: 100,
          resp_delay: 1000
        }
      ]
  end

  defmodule MultipleMatcher do
    use Faultex,
      injectors: [
        %Faultex.Injector.ErrorInjector{
          host: "*",
          path: "/auth/:id/*path",
          method: "POST",
          headers: [{"x-fault-inject", "auth-failed-1"}],
          percentage: 100,
          resp_headers: [],
          resp_status: 401,
          resp_body: "unauthorized-1"
        },
        %Faultex.Injector.ErrorInjector{
          host: "*",
          path: "/auth/:id/*path",
          method: "POST",
          headers: [{"x-fault-inject", "auth-failed-2"}],
          percentage: 100,
          resp_headers: [],
          resp_status: 401,
          resp_body: "unauthorized-2"
        },
      ]
  end

  test "match/4 are compile time match configures" do
    # matches
    assert {true, %Faultex.Injector.ErrorInjector{}} =
             Matcher.match?("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])

    # Method does not match
    assert {false, _} =
             Matcher.match?("*", "GET", ["test"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])

    # Headers does not match
    assert {false, _} =
             Matcher.match?("*", "GET", ["test"], [
               {"content-type", "application/json"}
             ])

    # Slow
    assert {true, %Faultex.Injector.SlowInjector{}} =
             Matcher.match?("*", "GET", ["slow"], [
               {"content-type", "application/json"}
             ])

    # disabled
    Application.put_env(:faultex, :disable, true)

    ExUnit.Callbacks.on_exit(fn ->
      Application.put_env(:faultex, :disable, false)
    end)

    assert {false, _} =
             Matcher.match?("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])
  end

  test "multiple match selects injector by header" do
    # header auth-failed-1 → unauthorized-1
    assert {true, %Faultex.Injector.ErrorInjector{resp_body: "unauthorized-1"}} =
             MultipleMatcher.match?("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed-1"}
             ])

    # header auth-failed-2 → unauthorized-2
    assert {true, %Faultex.Injector.ErrorInjector{resp_body: "unauthorized-2"}} =
             MultipleMatcher.match?("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed-2"}
             ])

    # header がどちらにもマッチしない → {false, nil}
    assert {false, nil} =
             MultipleMatcher.match?("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "unknown"}
             ])
  end
end
