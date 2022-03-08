defmodule Injex.Plug do
  @moduledoc """
    HTTPリクエストにマッチさせてエラーレスポンスを返すPlug
  """
  @behaviour Plug

  defmacro __using__(opts) do
    quote do
      use Injex, injectors: unquote(opts)[:injectors]
      use Plug.Router

      plug(Injex.Plug, matcher: __MODULE__)
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
      %Injex{} = injex ->
        conn =
          conn
          |> put_resp_headers(injex)
          |> send_resp(injex)

        conn = Plug.Conn.halt(conn)
        conn

      :pass ->
        conn
    end
  end

  def send_resp(conn, injex) do
    delay =
      case Map.get(injex, :resp_delay) do
        nil -> 0
        delay -> delay
      end

    Process.sleep(delay)

    conn =
      conn
      |> Plug.Conn.send_resp(injex.resp_status, injex.resp_body)

    conn
  end

  def put_resp_headers(conn, injex) do
    Enum.reduce(
      injex.resp_headers,
      conn,
      fn {k, v}, c ->
        Plug.Conn.put_resp_header(c, k, v)
      end
    )
  end

  def match(matcher, %Plug.Conn{} = conn) do
    %{
      host: _host,
      method: method,
      path_info: path_info,
      req_headers: req_headers
    } = conn

    matcher.match("*", method, path_info, req_headers)
  end
end
