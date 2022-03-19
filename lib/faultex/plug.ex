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
      %Faultex{} = injex ->
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
    resp_delay =
      case Map.get(injex, :resp_delay) do
        nil -> 0
        delay -> delay
      end

    if resp_delay do
      Process.sleep(injex.resp_delay)
    end

    if injex.resp_handler != nil do
      # TODO pattern match error handling
      {m, f} = injex.resp_handler

      %{
        resp_status: resp_status,
        resp_body: resp_body
      } = apply(m, f, [conn.host, conn.method, conn.path_info, conn.request_headers, injex])

      # TODO headers
      Plug.Conn.send_resp(conn, resp_status, resp_body)
    else
      # TODO headers
      Plug.Conn.send_resp(conn, injex.resp_status, injex.resp_body)
    end
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
