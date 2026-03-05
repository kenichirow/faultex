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

  use Faultex.Injector
  defstruct @__fields__ ++ [:injectors]

  @spec inject(t()) :: Faultex.Response.t()
  def inject(%__MODULE__{injectors: injectors}) do
    rand_fn = Application.get_env(:faultex, :rand_uniform, &:rand.uniform/1)
    index = rand_fn.(length(injectors)) - 1
    injectors |> Enum.at(index) |> Faultex.inject()
  end
end
