defmodule Injex.MatcherTest do
  use ExUnit.Case

  test "match/1 are compile time match configures" do
    # matches
    t =
      Injex.match("*", "POST", ["auth", "test", "register"], [
        {"x-fault-inject", "auth-failed"},
        {"content-type", "application/json"}
      ])

    assert %Injex{} = t

    # Method does not match
    t2 =
      Injex.match("*", "GET", ["auth", "test", "register"], [
        {"x-fault-inject", "auth-failed"},
        {"content-type", "application/json"}
      ])

    assert :pass == t2

    # Headers does not match
    t3 =
      Injex.match("*", "POST", ["auth", "test", "register"], [
        {"content-type", "application/json"}
      ])

    assert :pass == t3
  end

  test "match/2 are runtime" do
  end
end
