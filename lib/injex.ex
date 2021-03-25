defmodule Injex do
  @moduledoc """
  """

  @before_compile Injex.Matcher

  defstruct [
    :unmatch,
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

  def match(%HTTPoison.Request{
        method: method,
        headers: headers,
        url: url
      }) do
    req_headers = HTTPoison.process_request_headers(headers)
    method = String.upcase(to_string(method))
    %{host: host, path: path} = url |> URI.parse()

    path_info =
      path
      |> String.split("/")
      |> Enum.reject(&match?("", &1))

    do_match(host, method, path_info, req_headers)
  end

  def match(%Plug.Conn{} = conn) do
    %{
      host: _host,
      method: method,
      path_info: path_info,
      req_headers: req_headers
    } = conn

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
      end) ++
        [
          %Injex{
            id: :pass,
            unmatch: true
          }
        ]
    end

    def create_matcher_body(_, _, _, _, %Injex{unmatch: true}) do
      quote location: :keep do
        def do_match(_host, _method, _, _req_headers) do
          :pass
        end
      end
    end

    # mathches all host
    def create_matcher_body("*", method, path_match, headers, config) do
      quote do
        def do_match(
              _,
              unquote(method),
              [unquote_splicing(path_match)],
              req_headers
            ) do
          disabled? = Application.get_env(:injex, :disable, false)

          if not disabled? and Enum.any?(req_headers, &match?(unquote(headers), &1)) do
            unquote(Macro.escape(config))
          else
            :pass
          end
        end
      end
    end

    def create_matcher_body(host, method, path_match, headers, config) do
      quote do
        def do_match(
              unquote(host),
              unquote(method),
              [unquote_splicing(path_match)],
              req_headers
            ) do
          disabled? = Application.get_env(:injex, :disable, false)

          if not disabled? and Enum.any?(req_headers, &match?(unquote(headers), &1)) do
            unquote(Macro.escape(config))
          else
            :pass
          end
        end
      end
    end

    defmacro __before_compile__(_env) do
      for config <- build_matchers() do
        path_match = config.path_match
        host = config.host
        method = config.method
        headers = config.headers
        config = config
        create_matcher_body(host, method, path_match, headers, config)

        # host "*" での逆マッチに対応(Plugで必要)
        if host != "*" do
          create_matcher_body("*", method, path_match, headers, config)
        end
      end
    end
  end
end
