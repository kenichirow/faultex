defmodule Injex.MatcherTest do
  use ExUnit.Case

  test "match/4 are compile time match configures" do
    # matches
    assert %Injex{} =
             Injex.match("*", "POST", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])

    # Method does not match
    assert :pass ==
             Injex.match("*", "GET", ["auth", "test", "register"], [
               {"x-fault-inject", "auth-failed"},
               {"content-type", "application/json"}
             ])

    # Headers does not match
    assert :pass ==
             Injex.match("*", "POST", ["auth", "test", "register"], [
               {"content-type", "application/json"}
             ])
  end

  test "match/5 are runtime match" do
    assert %Injex{} =
             Injex.match(
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
             Injex.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [{"x-fault-inject", "auth-failed"}],
               matcher
             )

    assert %Injex{} =
             Injex.match(
               "https://example.com",
               "POST",
               ["auth", "test", "register"],
               [{"test", "test1"}, {"x-fault-inject", "auth-failed"}],
               matcher
             )
  end
end
