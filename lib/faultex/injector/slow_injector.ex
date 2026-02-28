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
    Faultex.Injector.apply_delay(injector)

    %Faultex.Response{action: :passthrough}
  end
end
