defmodule Faultex do
  @moduledoc """
  """

  defstruct [
    :id,
    :disable,
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

  defmacro __before_compile__(env) do
    injectors = Module.get_attribute(env.module, :__faultex_injectors__)

    for injector <- Faultex.build_injectors(injectors) do
      host = injector.host
      method = injector.method
      path_match = injector.path_match
      headers = injector.headers || []
      percentage = injector.percentage
      disable = injector.disable || false

      quote do
        def match(
              unquote(to_underscore(host)),
              unquote(to_underscore(method)),
              unquote(to_underscore(path_match)),
              req_headers
            ) do
          disabled? = Application.get_env(:injex, :disable, false) || unquote(disable)
          roll = Faultex.roll(unquote(percentage))
          match_headers? = Faultex.match_req_headers?(req_headers, unquote(headers))

          if roll and not disabled? and match_headers? do
            unquote(Macro.escape(injector))
          else
            :pass
          end
        end
      end
    end
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      injectors = Keyword.get(opts, :injectors, [])
      Module.put_attribute(__MODULE__, :__faultex_injectors__, injectors)
      @before_compile Faultex

      def match(host, method, path_match, req_headers, injector) do
        # TODO host, method, path, headers のマッチをやる
        disabled? =
          Application.get_env(:injector, :disable, false) ||
            (Map.get(injector, :disable) || false)

        roll = Faultex.roll(injector.percentage)
        match_headers? = Faultex.match_req_headers?(req_headers, injector.headers)

        if roll and not disabled? and match_headers? do
          injector
        else
          :pass
        end
      end

      def do_match(host, method, path_match, req_headers, injector) do
        case match(host, method, path_match, req_headers) do
          %Faultex{} = injector ->
            injector

          _ ->
            host_match? = Faultex.host_match?(host, injector.host)
            method_match? = Faultex.method_match?(method, injector.method)
            path_match? = Faultex.path_match?(method, injector.path)
            req_headers_match? = Faultex.match_req_headers?(req_headers, injector.headers)

            disabled? =
              Application.get_env(:injector, :disable, false) ||
                (Map.get(injector, :disable) || false)

            roll = Faultex.roll(injector.percentage)

            if host_match? and method_match? and path_match? and req_headers_match? and
                 not disabled? and roll do
              injector
            else
              :pass
            end
        end
      end

      def get_injectors(), do: @__faultex_injectors__
    end
  end

  # Generate struct for pattern match from config.exs
  def build_injectors(injectors) do
    Enum.map(injectors, fn injector ->
      do_build_injector(injector)
    end) ++
      [
        %Faultex{
          disable: true
        }
      ]
  end

  defp do_build_injector(injector_id) when is_atom(injector_id) do
    injector = Application.fetch_env!(:faultex, injector_id)

    path = Keyword.get(injector, :path, "*")
    host = Keyword.get(injector, :host, "*")
    method = Keyword.get(injector, :method, "GET")
    headers = Keyword.get(injector, :headers, [])
    percentage = Keyword.get(injector, :percentage, 100)

    resp_body = Keyword.get(injector, :resp_body, "")
    resp_status = Keyword.get(injector, :resp_status, 200)
    resp_headers = Keyword.get(injector, :resp_headers, [])
    resp_handler = Keyword.get(injector, :resp_handler, nil)
    resp_delay = Keyword.get(injector, :resp_delay, 0)
    disable = Keyword.get(injector, :disable, false)

    {vars, path_match} = Plug.Router.Utils.build_path_match(path)
    params_match = Plug.Router.Utils.build_path_params_match(vars)

    %Faultex{
      id: injector,
      disable: disable,
      params_match: params_match,
      vars: vars,
      host: host,
      method: method,
      path_match: path_match,
      percentage: percentage,
      headers: headers,
      resp_status: resp_status,
      resp_body: resp_body,
      resp_headers: resp_headers,
      resp_delay: resp_delay,
      resp_handler: resp_handler
    }
  end

  defp do_build_injector(injector) when is_map(injector) do
    path = Map.get(injector, :path, "*")
    host = Map.get(injector, :host, "*")
    method = Map.get(injector, :method, "GET")
    headers = Map.get(injector, :headers, [])
    percentage = Map.get(injector, :percentage, 100)

    resp_body = Map.get(injector, :resp_body, "")
    resp_status = Map.get(injector, :resp_status, 200)
    resp_headers = Map.get(injector, :resp_headers, [])
    resp_handler = Map.get(injector, :resp_handler, nil)
    resp_delay = Map.get(injector, :resp_delay, 0)
    disable = Map.get(injector, :disable, false)

    {vars, path_match} = Plug.Router.Utils.build_path_match(path)
    params_match = Plug.Router.Utils.build_path_params_match(vars)

    %Faultex{
      id: injector,
      disable: disable,
      params_match: params_match,
      vars: vars,
      host: host,
      method: method,
      path_match: path_match,
      percentage: percentage,
      headers: headers,
      resp_status: resp_status,
      resp_body: resp_body,
      resp_headers: resp_headers,
      resp_delay: resp_delay,
      resp_handler: resp_handler
    }
  end

  def host_match?(_host, nil), do: true
  def host_match?(_host, "*"), do: true
  def host_match?(host, expected), do: host == expected

  def method_match?(_method, nil), do: true
  def method_match?(_method, "*"), do: true
  def method_match?(method, expected), do: method == expected

  def path_match?(_path, nil), do: true
  def path_match?(_path, "*"), do: true

  # FIXME
  def path_match?(path, expected) do
    path == expected
  end

  defp to_underscore(nil) do
    quote do: _
  end

  defp to_underscore("*") do
    quote do: _
  end

  defp to_underscore(any) do
    any
  end

  def match_req_headers?(req_headers, headers) do
    Enum.all?(headers, fn header ->
      header in req_headers
    end)
  end

  def roll(100), do: true
  def roll(percentage), do: :rand.uniform(100) < percentage
end
