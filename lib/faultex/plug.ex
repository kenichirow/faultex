defmodule Faultex.Plug do
  @moduledoc """
    HTTPリクエストにマッチさせてエラーレスポンスを返すPlug
  """
  @behaviour Plug

  defmacro __using__(opts) do
    quote do
      use Faultex, unquote(opts)
      use Plug.Router

      plug(Faultex.Plug, matcher: __MODULE__)
    end
  end

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, opts) do
    matcher = opts[:matcher]

    case match(matcher, conn) do
      {true, %Faultex.Injector.SlowInjector{} = slow_injector} ->
        _ = Faultex.inject(slow_injector)
        conn

      {true, %Faultex.Injector.RejectInjector{} = reject_injector} ->
        _ = Faultex.inject(reject_injector)

        Plug.Conn.halt(conn)

      {false, _} ->
        conn
    end
  end

  def send_resp_and_halt(conn, injector) do
    resp = Faultex.inject(injector)

    conn
    |> put_resp_headers(resp.headers)
    |> Plug.Conn.send_resp(resp.status, resp.body)
    |> Plug.Conn.halt()
  end

  def put_resp_headers(conn, headers) do
    conn =
      Enum.reduce(
        headers,
        conn,
        fn {k, v}, c ->
          Plug.Conn.put_resp_header(c, k, v)
        end
      )

    conn
  end

  def match(matcher, %Plug.Conn{} = conn) do
    %{
      host: _host,
      method: method,
      path_info: path_info,
      req_headers: req_headers
    } = conn

    matcher.match?("*", method, path_info, req_headers)
  end
end
