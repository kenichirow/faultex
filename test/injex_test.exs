defmodule InjexTest do
  use ExUnit.Case

  defmodule Matcher do
    use Injex,
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
    assert %Injex{} =
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
    assert %Injex{} =
             Matcher.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [
                 {"x-fault-inject", "auth-failed"},
                 {"content-type", "application/json"}
               ],
               %Injex{percentage: 100, headers: [{"x-fault-inject", "auth-failed"}]}
             )
  end

  test "multiple header match" do
    matcher = %Injex{
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

    assert %Injex{} =
             Matcher.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [{"test", "test1"}, {"x-fault-inject", "auth-failed"}],
               matcher
             )
  end

  test "resp_header functions should override resp_body, resp_header, resp_status" do
    resp_handler = fn _req, _injex ->
      %Injex{
        resp_status: 400,
        resp_headers: [{"x-injex", "failed"}],
        resp_body: "request_failed"
      }
    end

    matcher = %Injex{
      percentage: 100,
      headers: [{"test", "test1"}, {"x-fault-inject", "auth-failed"}],
      resp_handler: {Injex.Handler, :handle_response}
    }

    assert %Injex{
             resp_status: 400,
             resp_headers: [{"x-injex", "failed"}],
             resp_body: "request_failed"
           } =
             Matcher.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [{"test", "test1"}, {"x-fault-inject", "auth-failed"}],
               matcher
             )
  end
end
