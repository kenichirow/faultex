defmodule Injex do
  @moduledoc """
  """

  @before_compile Injex.Matcher

  defstruct [
    :pass,
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

  defmodule Matcher do
    # Generate struct for pattern match from config.exs
    defp build_matchers() do
      failures = Application.get_env(:injex, :failures, [])

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
          response: response,
          pass: false
        }
      end) ++
        [
          %Injex{
            pass: true
          }
        ]
    end

    defp wildcard_to_underscore("*") do
      quote do: _
    end

    defp wildcard_to_underscore(any) do
      any
    end

    def create_matcher_body(_, _, _, _, %Injex{pass: true}) do
      quote location: :keep do
        def match(_host, _method, _, _req_headers) do
          :pass
        end
      end
    end

    def create_matcher_body(host, method, path_match, headers, config) do
      quote do
        def match(
              unquote(wildcard_to_underscore(host)),
              unquote(wildcard_to_underscore(method)),
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
        %{
          host: host,
          method: method,
          path_match: path_match,
          headers: headers
        } = config

        config = config
        create_matcher_body(host, method, path_match, headers, config)
      end
    end
  end
end
