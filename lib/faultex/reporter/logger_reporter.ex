defmodule Faultex.Reporter.LoggerReporter do
  @moduledoc """
  Reporter that logs injection events via Logger.
  """

  @behaviour Faultex.Reporter

  require Logger

  @impl Faultex.Reporter
  def report(event, injector, metadata) do
    Logger.info(
      "[Faultex] #{event} #{inspect(injector.__struct__)}",
      faultex_event: event,
      faultex_injector: injector,
      faultex_metadata: metadata
    )

    :ok
  end
end
