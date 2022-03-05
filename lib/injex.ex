defmodule Injex do
  @moduledoc """
  """

  @before_compile Injex.Matcher

  defstruct [
    :id,
    :pass,
    :host,
    :method,
    :path_match,
    :vars,
    :headers,
    :percentage,
    :resp_status,
    :resp_headers,
    :resp_handler,
    :resp_body,
    :resp_delay,
    :params_match
  ]

  defmodule Matcher do
    # Generate struct for pattern match from config.exs
    def build_matchers() do
      failures = Application.get_env(:injex, :failures, [])

      Enum.map(failures, fn id ->
        config = Application.fetch_env!(:injex, id)

        path = Keyword.get(config, :path, "*")
        host = Keyword.get(config, :host, "*")
        method = Keyword.get(config, :method, "GET")
        headers = Keyword.get(config, :headers, [])
        percentage = Keyword.get(config, :percentage, 100)

        resp_body = Keyword.get(config, :resp_body, "")
        resp_status = Keyword.get(config, :resp_status, 200)
        resp_headers = Keyword.get(config, :resp_headers, [])
        resp_delay = Keyword.get(config, :resp_delay, 0)

        {vars, path_match} = Plug.Router.Utils.build_path_match(path)
        params_match = Plug.Router.Utils.build_path_params_match(vars)

        %Injex{
          id: id,
          host: host,
          method: method,
          path_match: path_match,
          percentage: percentage,
          headers: headers,
          resp_status: resp_status,
          resp_body: resp_body,
          resp_headers: resp_headers,
          resp_delay: resp_delay,
          params_match: params_match,
          vars: vars,
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

    def create_match(_, _, _, _, _, %Injex{pass: true}) do
      quote location: :keep do
        def match(_host, _method, _, _req_headers) do
          :pass
        end
      end
    end

    def create_match(host, method, path_match, headers, percentage, config) do
      quote location: :keep do
        def match(
              unquote(wildcard_to_underscore(host)),
              unquote(wildcard_to_underscore(method)),
              [unquote_splicing(path_match)],
              req_headers
            ) do
          disabled? = Application.get_env(:injex, :disable, false)
          roll = Injex.roll(unquote(percentage))
          match_headers? = Injex.match_req_headers?(req_headers, unquote(headers))

          if roll and not disabled? and match_headers? do
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
          percentage: percentage,
          headers: headers
        } = config

        create_match(host, method, path_match, headers, percentage, config)
      end
    end
  end

  def match(host, method, path, req_headers, injex) do
    # TODO host, method, path, headers のマッチをやる
    disabled? = Application.get_env(:injex, :disable, false)
    roll = Injex.roll(injex.percentage)
    match_headers? = Injex.match_req_headers?(req_headers, injex.headers)

    if roll and not disabled? and match_headers? do
      if injex.resp_handler != nil do
        # TODO request body
        # MFA 
        injex.resp_handler.(%{}, injex)
      else
        injex
      end
    else
      :pass
    end
  end

  def match_req_headers?(req_headers, headers) do
    Enum.all?(headers, fn header ->
      header in req_headers
    end)
  end

  def roll(100), do: true
  def roll(percentage), do: :rand.uniform(100) < percentage
end
