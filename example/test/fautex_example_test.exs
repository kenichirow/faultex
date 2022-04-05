defmodule FautexExampleTest do
  use ExUnit.Case
  doctest FautexExample

  test "greets the world" do
    assert FautexExample.hello() == :world
  end
end
