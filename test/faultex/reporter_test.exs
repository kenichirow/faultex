defmodule Faultex.ReporterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  describe "Faultex.Reporter.Logger" do
    test "logs started event at debug level" do
      event = %{
        state: :started,
        injector: Faultex.Injector.ErrorInjector,
        method: "GET",
        path: "/test"
      }

      log = capture_log([level: :debug], fn -> Faultex.Reporter.Logger.report(event) end)
      assert log =~ "Faultex: Faultex.Injector.ErrorInjector GET /test started"
    end

    test "logs finished event at debug level" do
      event = %{
        state: :finished,
        injector: Faultex.Injector.ErrorInjector,
        method: "GET",
        path: "/test"
      }

      log = capture_log([level: :debug], fn -> Faultex.Reporter.Logger.report(event) end)
      assert log =~ "Faultex: Faultex.Injector.ErrorInjector GET /test finished"
    end
  end

  describe "Faultex.Reporter.report/1 dispatch" do
    test "dispatches to default Logger reporter" do
      event = %{
        state: :started,
        injector: Faultex.Injector.SlowInjector,
        method: "POST",
        path: "/api"
      }

      log = capture_log([level: :debug], fn -> Faultex.Reporter.report(event) end)
      assert log =~ "Faultex: Faultex.Injector.SlowInjector POST /api started"
    end

    test "dispatches to custom reporter" do
      defmodule TestReporter do
        @behaviour Faultex.Reporter
        @impl true
        def report(event) do
          send(self(), {:reported, event})
          :ok
        end
      end

      Application.put_env(:faultex, :reporter, TestReporter)

      on_exit(fn ->
        Application.delete_env(:faultex, :reporter)
      end)

      event = %{
        state: :started,
        injector: Faultex.Injector.ErrorInjector,
        method: "GET",
        path: "/custom"
      }

      Faultex.Reporter.report(event)
      assert_received {:reported, ^event}
    end

    test "does not crash when reporter raises" do
      defmodule CrashingReporter do
        @behaviour Faultex.Reporter
        @impl true
        def report(_event), do: raise("boom")
      end

      Application.put_env(:faultex, :reporter, CrashingReporter)

      on_exit(fn ->
        Application.delete_env(:faultex, :reporter)
      end)

      event = %{
        state: :started,
        injector: Faultex.Injector.ErrorInjector,
        method: "GET",
        path: "/crash"
      }

      assert :ok = Faultex.Reporter.report(event)
    end
  end
end
