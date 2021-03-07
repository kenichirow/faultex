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
    case Injex.match(conn) do
      %Injex{} = resp ->
        send_resp(conn, resp)

      :pass ->
        conn
    end
  end

  defp send_resp(conn, %Injex{status: status, response: response}) do
    Plug.Conn.send_resp(conn, status, response)
  end
end
