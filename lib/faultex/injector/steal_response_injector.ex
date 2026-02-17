defmodule Faultex.Injector.StealResponseInjector do
  @moduledoc """
  Simulates a stolen response where the server processes the request but the response never reaches the client.
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

  defstruct [
    :id,
    :disable,
    :host,
    :method,
    :path,
    :headers,
    :percentage,
    :resp_delay
  ]

  @spec inject(t()) :: Faultex.Response.t()
  def inject(_injector) do
    %Faultex.Response{action: :steal}
  end
end

defimpl Faultex.Injector, for: Faultex.Injector.StealResponseInjector do
  def inject(injector), do: Faultex.Injector.StealResponseInjector.inject(injector)
end
