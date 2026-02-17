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
          resp_handler: term(),
          resp_body: String.t() | nil,
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
    :resp_status,
    :resp_headers,
    :resp_handler,
    :resp_body,
    :resp_delay
  ]

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

    %Faultex.Response{
      action: :response,
      status: injector.resp_status,
      headers: injector.resp_headers,
      body: injector.resp_body
    }
  end
end

defimpl Faultex.Injector, for: Faultex.Injector.ErrorInjector do
  def inject(injector), do: Faultex.Injector.ErrorInjector.inject(injector)
end
