defmodule InjexTest do
  use ExUnit.Case

  defmodule Matcher do
    use Injex, injectors: []
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
  end

  test "match/5 are runtime match" do
    # 確かにこれはマッチしない
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
    resp_handler = fn req, injex ->
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
