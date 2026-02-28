defmodule Faultex.Reporter do
  @moduledoc """
  Behaviour for reporting fault injection events.
  Implement this behaviour to receive notifications about injector lifecycle.
  """

  @type state :: :started | :finished | :skipped
  @type name :: String.t()

  @callback report(name, state) :: :ok

  @doc """
  Dispatches a report to the configured reporter module.
  Default reporter is `Faultex.Reporter.Logger`.
  Configure via `config :faultex, reporter: MyReporter`.
  """
  @spec report(name, state) :: :ok
  def report(name, state) do
    reporter = Application.get_env(:faultex, :reporter, Faultex.Reporter.Logger)
    reporter.report(name, state)
  end
end
