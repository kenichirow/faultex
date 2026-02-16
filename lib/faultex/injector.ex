defmodule Faultex.Injector do
  @callback inject(request :: term()) :: Faultex.Response.t()
end

defmodule Faultex.Response do
  @type t :: %__MODULE__{
          status: integer() | nil,
          headers: [{String.t(), String.t()}] | nil,
          body: String.t() | nil
        }

  defstruct [:status, :headers, :body]
end

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

  @behaviour Faultex.Injector

  @impl Faultex.Injector
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
      status: injector.resp_status,
      headers: injector.resp_headers,
      body: injector.resp_body
    }
  end
end

defmodule Faultex.Injector.SlowInjector do
  @moduledoc """
  Inject response delay
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

  @behaviour Faultex.Injector

  @impl Faultex.Injector
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

    %Faultex.Response{}
  end
end

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

  @behaviour Faultex.Injector

  @impl Faultex.Injector
  @spec inject(t()) :: Faultex.Response.t()
  def inject(_injector) do
    %Faultex.Response{headers: [], body: ""}
  end
end
