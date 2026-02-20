defmodule Faultex.Reporter.LoggerReporterTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  test "logs injection event with injector type" do
    injector = %Faultex.Injector.ErrorInjector{resp_status: 500}

    log =
      capture_log(fn ->
        Faultex.Reporter.LoggerReporter.report(:injected, injector, %{
          response: %Faultex.Response{}
        })
      end)

    assert log =~ "[Faultex]"
    assert log =~ "injected"
    assert log =~ "ErrorInjector"
  end

  test "returns :ok" do
    assert :ok =
             Faultex.Reporter.LoggerReporter.report(
               :injected,
               %Faultex.Injector.SlowInjector{},
               %{response: %Faultex.Response{}}
             )
  end
end
