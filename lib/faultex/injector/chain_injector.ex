defmodule Faultex.Injector.ChainInjector do
  @moduledoc """
  Execute multiple injectors in sequence
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

  @behaviour Faultex.Injector

  @impl Faultex.Injector
  @spec inject(t()) :: Faultex.Response.t()
  def inject(%__MODULE__{injectors: injectors}) do
    Enum.reduce(injectors, %Faultex.Response{}, fn inj, _acc ->
      Faultex.inject(inj)
    end)
  end
end
