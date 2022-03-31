defmodule Faultex.Injector do
  @callback inject(requet :: term) :: Faultex.Response | :pass
end

defmodule Faultex.Response do
  defstruct [:status, :headers, :body]
end

defmodule Faultex.Injector.FaultInjector do
  @moduledoc """
  Inject fault response immediately
  """

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
  def inject(injector) do
    resp_delay =
      case Map.get(injector, :resp_delay) do
        nil -> 0
        delay -> delay
      end

    if resp_delay != 0 do
      Process.sleep(resp_delay)
    end

    # if injector.resp_handler != nil do
    #   {m, f} = injector.resp_handler

    #   %{
    #     resp_status: resp_status,
    #     resp_body: resp_body
    #   } = apply(m, f, [conn.host, conn.method, conn.path_info, conn.request_headers, injector])
    # %Faultex.Response{status: resp_status, headers: injector.resp_headers body: resp_body}

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

  @behaviour Faultex.Injector

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

  @impl Faultex.Injector
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
  def inject(_injector) do
    %Faultex.Response{headers: [], body: ""}
  end
end
