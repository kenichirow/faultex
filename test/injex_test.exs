defmodule InjexTest do
  use ExUnit.Case
  doctest Injex

  test "greets the world" do
    assert Injex.hello() == :world

    conn = Plug.Test.conn("GET", "das/register")
    IO.inspect(conn)
    x = Plug.Router.__route__("GET", "das/register", [], [])
    IO.inspect(x)
  end
end
