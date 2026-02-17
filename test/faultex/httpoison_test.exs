defmodule Faultex.HTTPoisonTest do
  use ExUnit.Case

  defmodule MyApp.HTTPoison do
    use Faultex.HTTPoison,
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

  defmodule MyApp.RejectHTTPoison do
    use Faultex.HTTPoison,
      injectors: [
        %Faultex.Injector.RejectInjector{
          host: "reject.example.com",
          path: "/api",
          method: "GET",
          percentage: 100
        }
      ]
  end

  defmodule MyApp.StealHTTPoison do
    use Faultex.HTTPoison,
      injectors: [
        %Faultex.Injector.StealResponseInjector{
          host: "github.com",
          path: "/steal",
          method: "GET",
          percentage: 100
        }
      ]
  end

  test "StealResponseInjector sends request then returns error with reason :closed" do
    {:error, %HTTPoison.Error{reason: :closed}} =
      MyApp.StealHTTPoison.get("https://github.com/steal")
  end

  test "StealResponseInjector passes through when not matched" do
    {:ok, res} = MyApp.StealHTTPoison.get("https://github.com/")
    assert res.status_code == 200
  end

  test "RejectInjector returns error with reason :closed" do
    {:error, %HTTPoison.Error{reason: :closed}} =
      MyApp.RejectHTTPoison.get("https://reject.example.com/api")
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
