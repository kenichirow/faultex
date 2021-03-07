defmodule Injex do
  defstruct [
    :host,
    :method,
    :status,
    :path_match,
    :vars,
    :headers,
    :params_match,
    :response
  ]

  defmodule Matcher do
    defp build_matchers() do
      _disable = Application.get_env(:injex, :disable, false)
      failures = Application.get_env(:injex, :failures, [])

      # before_sendのタイミングでレスポンスを返すようにする？
      Enum.map(failures, fn config ->
        config = Application.fetch_env!(:injex, config)
        path = Keyword.get(config, :path)
        host = Keyword.get(config, :host)
        method = Keyword.get(config, :method)
        response = Keyword.get(config, :response, "")
        status = Keyword.get(config, :status, 200)
        headers = Keyword.get(config, :header)

        {vars, path_match} = Plug.Router.Utils.build_path_match(path)
        params_match = Plug.Router.Utils.build_path_params_match(vars)

        %Injex{
          host: host,
          method: method,
          status: status,
          path_match: path_match,
          vars: vars,
          headers: headers,
          params_match: params_match,
          response: response
        }
      end)
    end

    defmacro __before_compile__(_env) do
      matchers = build_matchers()

      for config <- matchers do
        path_match = config.path_match
        host = config.host
        method = config.method
        headers = config.headers
        config = config

        quote do
          def do_match(
                unquote(host),
                unquote(method),
                [unquote_splicing(path_match)],
                req_headers
              ) do
            if Enum.any?(req_headers, &match?(unquote(headers), &1)) do
              unquote(Macro.escape(config))
            else
              :pass
            end
          end

          def do_match(_, unquote(method), [unquote_splicing(path_match)], req_headers) do
            if Enum.any?(req_headers, &match?(unquote(headers), &1)) do
              unquote(Macro.escape(config))
            else
              :pass
            end
          end
        end
      end
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
      %Injex{} = resp ->
        send_resp(conn, resp)

      :pass ->
        conn
    end
  end

  defp match(conn) do
    %{
      host: _host,
      method: method,
      path_info: path_info,
      req_headers: req_headers
    } = conn

    do_match("*", method, path_info, req_headers)
  end

  defp send_resp(conn, %Injex{status: status, response: response}) do
    Plug.Conn.send_resp(conn, status, response)
  end
end
