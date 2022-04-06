defmodule FaultexExampleTest do
  use ExUnit.Case
  doctest FaultexExample

  test "greets the world" do
    assert FaultexExample.hello() == :world
  end
end
