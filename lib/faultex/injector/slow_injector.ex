defmodule Faultex.Injector.SlowInjector do
  @moduledoc """
  Inject response delay.

  Sleeps for `resp_delay` milliseconds, then passes through to the original
  handler (Plug pipeline or HTTPoison request) without modifying the response.
  """

  @type t :: %__MODULE__{
          id: term(),
          disable: boolean() | nil,
          host: String.t() | nil,
          method: String.t() | nil,
          path: String.t() | nil,
          headers: [{String.t(), String.t()}] | nil,
          percentage: integer() | nil,
          resp_delay: integer() | nil
        }

  use Faultex.Injector
  defstruct @__fields__ ++ [:resp_delay]

  @spec inject(t()) :: Faultex.Response.t()
  def inject(injector) do
    resp_delay =
      case Map.get(injector, :resp_delay) do
        nil -> 0
        delay -> delay
      end

    if resp_delay != 0 do
      Process.sleep(resp_delay)
    end

    %Faultex.Response{action: :passthrough}
  end
end
