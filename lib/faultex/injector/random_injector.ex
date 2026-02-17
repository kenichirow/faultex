defmodule Faultex.Injector.RandomInjector do
  @moduledoc """
  Randomly select one injector from a list to execute
  """

  @type t :: %__MODULE__{
          id: term(),
          disable: boolean() | nil,
          host: String.t() | nil,
          method: String.t() | nil,
          path: String.t() | nil,
          headers: [{String.t(), String.t()}] | nil,
          percentage: integer() | nil,
          injectors: [term()]
        }

  defstruct [
    :id,
    :disable,
    :host,
    :method,
    :path,
    :headers,
    :percentage,
    :injectors
  ]

  @spec inject(t()) :: Faultex.Response.t()
  def inject(%__MODULE__{injectors: injectors}) do
    injectors |> Enum.random() |> Faultex.inject()
  end
end

defimpl Faultex.Injector, for: Faultex.Injector.RandomInjector do
  def inject(injector), do: Faultex.Injector.RandomInjector.inject(injector)
end
