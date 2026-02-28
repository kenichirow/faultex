defmodule Faultex.Injector.ErrorInjector do
  @moduledoc """
  Inject error response immediately
  """

  @type t :: %__MODULE__{
          id: term(),
          disable: boolean() | nil,
          host: String.t() | nil,
          method: String.t() | nil,
          path: String.t() | nil,
          headers: [{String.t(), String.t()}] | nil,
          percentage: integer() | nil,
          resp_status: integer() | nil,
          resp_headers: [{String.t(), String.t()}] | nil,
          resp_body: String.t() | nil,
          resp_delay: integer() | nil
        }

  use Faultex.Injector
  defstruct @__fields__ ++ [:resp_status, :resp_headers, :resp_body, :resp_delay]

  @spec inject(t()) :: Faultex.Response.t()
  def inject(injector) do
    Faultex.Injector.apply_delay(injector)

    %Faultex.Response{
      action: :response,
      status: injector.resp_status,
      headers: injector.resp_headers,
      body: injector.resp_body
    }
  end
end
