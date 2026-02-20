defmodule Faultex.Reporter do
  @moduledoc """
  Behaviour for receiving notifications when fault injection occurs.

  Configure a reporter via Application env:

      config :faultex, :reporter, MyApp.FaultexReporter

  """

  @callback report(event :: atom(), injector :: struct(), metadata :: map()) :: :ok
end
