defmodule Faultex.Injector.RejectInjector do
  @moduledoc """
  inject abort with empty response
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
  def inject(_injector) do
    %Faultex.Response{action: :reject, headers: [], body: ""}
  end
end
