defmodule Injex.HTTPoisonTest do
  use ExUnit.Case

  test "Request to remote server" do
    {:ok, res} = Injex.HTTPoison.get("https://github.com/", [])
    assert res.status_code == 200

    {:ok, res} = Injex.HTTPoison.get("https://github.com/foo", [])
    assert res.status_code == 200

    {:ok, res} = Injex.HTTPoison.get("https://github.com/foo", [{"x-fault-inject", "github"}])

    assert res.status_code == 400
  end
end
