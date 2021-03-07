defmodule Injex do
  @moduledoc """
  """

  @before_compile Injex.Matcher

  defstruct [
    :id,
    :host,
    :method,
    :status,
    :path_match,
    :vars,
    :headers,
    :params_match,
    :response
  ]

  def match(%Plug.Conn{} = conn) do
    %{
      host: _host,
      method: method,
      path_info: path_info,
      req_headers: req_headers
    } = conn

    # TODO "*" をどうにかする
    do_match("*", method, path_info, req_headers)
  end

  defmodule Matcher do
    defp build_matchers() do
      failures = Application.get_env(:injex, :failures, [])

      # before_sendのタイミングでレスポンスを返すようにする？
      Enum.map(failures, fn id ->
        config = Application.fetch_env!(:injex, id)
        path = Keyword.get(config, :path, "*")
        host = Keyword.get(config, :host, "*")
        method = Keyword.get(config, :method, "GET")
        response = Keyword.get(config, :response, "")
        status = Keyword.get(config, :status, 200)
        headers = Keyword.get(config, :header, [])

        {vars, path_match} = Plug.Router.Utils.build_path_match(path)
        params_match = Plug.Router.Utils.build_path_params_match(vars)

        %Injex{
          id: id,
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
            disabled? = Application.get_env(:injex, :disable, false)

            if Enum.any?(req_headers, &match?(unquote(headers), &1)) and not disabled? do
              unquote(Macro.escape(config))
            else
              :pass
            end
          end

          # host "*" でのマッチに対応
          case unquote(host) do
            "*" ->
              :ok

            _ ->
              def do_match(_, unquote(method), [unquote_splicing(path_match)], req_headers) do
                disabled? = Application.get_env(:injex, :disable, false)

                if Enum.any?(req_headers, &match?(unquote(headers), &1)) and not disabled? do
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
end
