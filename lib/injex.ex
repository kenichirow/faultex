defmodule Injex do
  defmodule Matcher do
    defmacro __before_compile__(_env) do
      configs = [
        %{
          # hostはrequesする時しか使わない
          host: "*",
          url: "das/auth/:game_id/:game_env/register",
          status: 400,
          response: "invalid",
          resp_handler: fn _conn, _matched_resp -> :ok end,
          header: {"x-gumi-failure-injection", "register-failed"}
        }
      ]

      # configの最後に 全マッチする関数が必要
      # hostがあるrequest用の設定とレスポンス用の設定を別でパターンマッチさせるのはどうか
      Enum.map(configs, fn config ->
        {vars, path_match} = Plug.Router.Utils.build_path_match(config.url)
        params_match = Plug.Router.Utils.build_path_params_match(vars)
        response = config.response
        status = config.status
        header = config.header

        quote do
          def do_match(host, method, [unquote_splicing(path_match)], req_headers) do
            if Enum.any?(req_headers, &match?(unquote(header), &1)) do
              # ヘッダーにマッチさせてエラー抽選する
              %{
                params: unquote(params_match),
                status: unquote(status),
                response: unquote(response)
              }
            else
              :unmatch
            end
          end
        end
      end)
    end

  end
end

defmodule Injex.HTTPoison do
end

defmodule Injex.Plug do
  @behaviour Plug
  @before_compile Injex.Matcher

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(conn, _opts) do
    case match(conn) do
      %{status: status, response: resp} ->
        Plug.Conn.send_resp(conn, status, resp)

      :ok ->
        conn
    end
  end

  def match(conn) do
    %{
      host: _host,
      method: method,
      request_path: request_path,
      req_headers: req_headers
    } = conn

    request_path =
      request_path
      |> String.split("/")
      |> Enum.reject(&match?("", &1))

    case do_match("*", method, request_path, req_headers) do
      :unmatch -> :ok
      match -> match
    end
  end
end
