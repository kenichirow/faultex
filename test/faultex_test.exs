defmodule FaultexTest do
  use ExUnit.Case

  defmodule Matcher do
    use Faultex,
      injectors: [
        %Faultex.Injector{
          host: "*",
          path: "/auth/:id/*path",
          method: "POST",
          headers: [{"x-fault-inject", "auth-failed"}],
          percentage: 100,
          resp_headers: [],
          resp_status: 401,
          resp_body: "unauthorized",
          resp_delay: 1000
        }
      ]
  end

  test "match/4 are compile time match configures" do
    # matches
    assert {true, %Faultex.Injector{}} =
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
end
