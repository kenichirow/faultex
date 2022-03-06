defmodule Injex.Plug do
  @moduledoc """
    HTTPリクエストにマッチさせてエラーレスポンスを返すPlug
  """
  @behaviour Plug

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, _opts) do
    case match(conn) do
      %Injex{} = injex ->
        conn
        |> put_resp_headers(injex)
        |> send_resp(injex)

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

    conn
    |> Plug.Conn.send_resp(injex.resp_status, injex.resp_body)
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

  def match(%Plug.Conn{} = conn) do
    %{
      host: _host,
      method: method,
      path_info: path_info,
      req_headers: req_headers
    } = conn

    Injex.match("*", method, path_info, req_headers)
  end
end
