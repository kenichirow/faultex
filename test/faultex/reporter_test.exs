defmodule Faultex.ReporterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  describe "Faultex.Reporter.Logger" do
    test "logs started state at debug level" do
      log =
        capture_log([level: :debug], fn ->
          Faultex.Reporter.Logger.report("ErrorInjector GET /test", :started)
        end)

      assert log =~ "Faultex: ErrorInjector GET /test started"
    end

    test "logs finished state at debug level" do
      log =
        capture_log([level: :debug], fn ->
          Faultex.Reporter.Logger.report("ErrorInjector GET /test", :finished)
        end)

      assert log =~ "Faultex: ErrorInjector GET /test finished"
    end

    test "logs skipped state at debug level" do
      log =
        capture_log([level: :debug], fn ->
          Faultex.Reporter.Logger.report("GET /test", :skipped)
        end)

      assert log =~ "Faultex: GET /test skipped"
    end
  end

  describe "Faultex.Reporter.report/2 dispatch" do
    test "dispatches to configured reporter" do
      log =
        capture_log([level: :debug], fn ->
          Faultex.Reporter.report("TestInjector GET /api", :started)
        end)

      assert log =~ "Faultex: TestInjector GET /api started"
    end
  end
end
