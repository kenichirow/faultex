defmodule Injex.HTTPoisonTest do
  use ExUnit.Case

  defmodule MyApp.HTTPoison do
    use Injex.HTTPoison,
      injectors: [
        %{
          host: "github.com",
          path: "/foo",
          method: "GET",
          headers: [{"x-fault-inject", "github"}],
          percentage: 100,
          resp_headers: [],
          resp_status: 400,
          resp_body: "{}",
          resp_delay: 1000
        }
      ]
  end

  test "Request to remote server" do
    {:ok, res} = MyApp.HTTPoison.get("https://github.com/", [])
    assert res.status_code == 200

    {:ok, res} = MyApp.HTTPoison.get("https://github.com/foo", [])
    assert res.status_code == 200
    
    {:ok, res} = MyApp.HTTPoison.get("https://github.com/", [{"x-fault-inject", "github"}])
    assert res.status_code == 200

    {:ok, res} = MyApp.HTTPoison.get("https://github.com/foo", [{"x-fault-inject", "github"}])
    assert res.status_code == 400
  end
end
