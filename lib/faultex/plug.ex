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
  @spec init(Keyword.t()) :: Keyword.t()
  def init(opts) do
    opts
  end

  @impl Plug
  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, opts) do
    matcher = opts[:matcher]

    case match(matcher, conn) do
      {true, %Faultex.Injector.SlowInjector{} = slow_injector} ->
        _ = Faultex.inject(slow_injector)
        conn

      {true, injector} ->
        send_resp_and_halt(conn, injector)

      {false, _} ->
        conn
    end
  end

  @spec send_resp_and_halt(Plug.Conn.t(), Faultex.Matcher.injector()) :: Plug.Conn.t()
  def send_resp_and_halt(conn, injector) do
    resp = Faultex.inject(injector)

    conn
    |> put_resp_headers(resp.headers)
    |> Plug.Conn.send_resp(resp.status, resp.body)
    |> Plug.Conn.halt()
  end

  @spec put_resp_headers(Plug.Conn.t(), [{String.t(), String.t()}] | nil) :: Plug.Conn.t()
  def put_resp_headers(conn, nil), do: conn
  def put_resp_headers(conn, []), do: conn

  def put_resp_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {k, v}, c ->
      Plug.Conn.put_resp_header(c, k, v)
    end)
  end

  @spec match(module(), Plug.Conn.t()) :: Faultex.Matcher.match_result()
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
