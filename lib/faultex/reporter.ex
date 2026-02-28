defmodule Faultex.Reporter do
  @moduledoc """
  Behaviour for reporting fault injection events.
  Implement this behaviour to receive notifications about injector lifecycle.
  """

  @type state :: :started | :finished
  @type event :: %{
          state: state(),
          injector: module(),
          method: String.t(),
          path: String.t()
        }

  @callback report(event()) :: :ok

  @doc """
  Dispatches a report to the configured reporter module.
  Default reporter is `Faultex.Reporter.Logger`.
  Configure via `config :faultex, reporter: MyReporter`.

  Reporter exceptions are caught to prevent reporting failures
  from breaking request processing.
  """
  @spec report(event()) :: :ok
  def report(event) do
    reporter = Application.get_env(:faultex, :reporter, Faultex.Reporter.Logger)

    try do
      reporter.report(event)
    rescue
      _ -> :ok
    end
  end
end
