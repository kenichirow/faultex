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
      %Injex{resp_status: resp_status, resp_body: resp_body} ->
        Plug.Conn.send_resp(conn, resp_status, resp_body)

      :pass ->
        conn
    end
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
