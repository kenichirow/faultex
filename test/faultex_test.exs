defmodule FaultexTest do
  use ExUnit.Case

  defmodule Matcher do
    use Faultex,
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
  end

  test "match/4 are compile time match configures" do
    # matches
    assert %Faultex{} =
             Matcher.match("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])

    # Method does not match
    assert :pass ==
             Matcher.match("*", "GET", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])

    # Headers does not match
    assert :pass ==
             Matcher.match("*", "POST", ["auth", "test", "register"], [
               {"content-type", "application/json"}
             ])

    # disabled
    Application.put_env(:injex, :disable, true)

    ExUnit.Callbacks.on_exit(fn ->
      Application.put_env(:injex, :disable, false)
    end)

    assert :pass =
             Matcher.match("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])
  end

  test "match/5 are runtime match" do
    assert %Faultex{} =
             Matcher.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [
                 {"x-fault-inject", "auth-failed"},
                 {"content-type", "application/json"}
               ],
               %Faultex{percentage: 100, headers: [{"x-fault-inject", "auth-failed"}]}
             )
  end

  test "multiple header match" do
    matcher = %Faultex{
      percentage: 100,
      headers: [{"test", "test1"}, {"x-fault-inject", "auth-failed"}]
    }

    assert :pass =
             Matcher.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [{"x-fault-inject", "auth-failed"}],
               matcher
             )

    assert %Faultex{} =
             Matcher.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [{"test", "test1"}, {"x-fault-inject", "auth-failed"}],
               matcher
             )
  end
end
