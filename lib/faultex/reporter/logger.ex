defmodule Faultex.Reporter.Logger do
  @moduledoc """
  Default reporter that logs fault injection events using Elixir's Logger at debug level.
  """
  @behaviour Faultex.Reporter

  require Logger

  @impl true
  def report(name, state) do
    Logger.debug(fn -> "Faultex: #{name} #{state}" end)
    :ok
  end
end
