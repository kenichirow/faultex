defmodule Faultex.Reporter.Logger do
  @moduledoc """
  Default reporter that logs fault injection events using Elixir's Logger at debug level.
  """
  @behaviour Faultex.Reporter

  require Logger

  @impl true
  def report(%{state: state, injector: injector, method: method, path: path}) do
    Logger.debug(fn ->
      "Faultex: #{inspect(injector)} #{method} #{path} #{state}"
    end)

    :ok
  end
end
