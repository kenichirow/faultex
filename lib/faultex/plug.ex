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
      {true, injector} ->
        resp = Faultex.inject(injector)

        case resp.action do
          :passthrough ->
            conn

          :reject ->
            conn |> Plug.Conn.halt()

          :response ->
            send_resp_and_halt(conn, resp)

          :steal ->
            Plug.Conn.register_before_send(conn, fn conn ->
              Process.exit(self(), :kill)
              conn
            end)
        end

      {false, _} ->
        conn
    end
  end

  @spec send_resp_and_halt(Plug.Conn.t(), Faultex.Response.t()) :: Plug.Conn.t()
  defp send_resp_and_halt(conn, resp) do
    conn
    |> put_resp_headers(resp.headers)
    |> Plug.Conn.send_resp(resp.status, resp.body)
    |> Plug.Conn.halt()
  end

  @spec put_resp_headers(Plug.Conn.t(), [{String.t(), String.t()}] | nil) :: Plug.Conn.t()
  defp put_resp_headers(conn, nil), do: conn
  defp put_resp_headers(conn, []), do: conn

  defp put_resp_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {k, v}, c ->
      Plug.Conn.put_resp_header(c, k, v)
    end)
  end

  @spec match(module(), Plug.Conn.t()) :: Faultex.Matcher.match_result()
  defp match(matcher, %Plug.Conn{} = conn) do
    %{
      host: host,
      method: method,
      path_info: path_info,
      req_headers: req_headers
    } = conn

    matcher.match?(host, method, path_info, req_headers)
  end
end
