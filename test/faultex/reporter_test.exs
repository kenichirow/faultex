defmodule Faultex.ReporterTest do
  use ExUnit.Case

  defmodule TestReporter do
    @behaviour Faultex.Reporter

    @impl Faultex.Reporter
    def report(event, injector, metadata) do
      send(self(), {:reported, event, injector, metadata})
      :ok
    end
  end

  setup do
    on_exit(fn -> Application.delete_env(:faultex, :reporter) end)
  end

  describe "reporter integration" do
    test "calls reporter when configured" do
      Application.put_env(:faultex, :reporter, TestReporter)

      injector = %Faultex.Injector.ErrorInjector{
        resp_status: 500,
        resp_body: "error"
      }

      resp = Faultex.inject(injector)

      assert_received {:reported, :injected, ^injector, %{response: ^resp}}
    end

    test "does not crash when reporter is not configured" do
      Application.delete_env(:faultex, :reporter)

      injector = %Faultex.Injector.ErrorInjector{
        resp_status: 500,
        resp_body: "error"
      }

      resp = Faultex.inject(injector)
      assert %Faultex.Response{} = resp
    end

    test "reporter receives correct injector type for each injector" do
      Application.put_env(:faultex, :reporter, TestReporter)

      for {injector, expected_struct} <- [
            {%Faultex.Injector.ErrorInjector{resp_status: 500}, Faultex.Injector.ErrorInjector},
            {%Faultex.Injector.SlowInjector{resp_delay: 0}, Faultex.Injector.SlowInjector},
            {%Faultex.Injector.RejectInjector{}, Faultex.Injector.RejectInjector}
          ] do
        Faultex.inject(injector)
        assert_received {:reported, :injected, received_injector, _}
        assert received_injector.__struct__ == expected_struct
      end
    end

    test "reporter receives response in metadata" do
      Application.put_env(:faultex, :reporter, TestReporter)

      Faultex.inject(%Faultex.Injector.ErrorInjector{
        resp_status: 503,
        resp_body: "timeout"
      })

      assert_received {:reported, :injected, _, %{response: %Faultex.Response{status: 503}}}
    end
  end
end
