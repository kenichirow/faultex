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
    injectors = Module.get_attribute(env.module, :injectors)

    for config <- Faultex.build_injectors(injectors) do
      host = config.host
      method = config.method
      path_match = config.path_match
      headers = config.headers || []
      resp_handler = config.resp_handler
      percentage = config.percentage
      disable = config.disable || false
      params_match = config.params_match

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

          # resp_handler はここで実行しない params_match
          if roll and not disabled? and match_headers? do
            if unquote(resp_handler) != nil do
              {m, f} = unquote(resp_handler)

              apply(m, f, [
                unquote(host),
                unquote(method),
                unquote(path_match),
                req_headers,
                unquote(Macro.escape(config))
              ])
            else
              unquote(Macro.escape(config))
            end
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
      Module.put_attribute(__MODULE__, :injectors, injectors)
      @before_compile Faultex

      def match(host, method, path_match, req_headers, injex) do
        # TODO host, method, path, headers のマッチをやる
        disabled? =
          Application.get_env(:injex, :disable, false) || (Map.get(injex, :disable) || false)

        roll = Faultex.roll(injex.percentage)
        match_headers? = Faultex.match_req_headers?(req_headers, injex.headers)

        if roll and not disabled? and match_headers? do
          if injex.resp_handler != nil do
            {m, f} = injex.resp_handler
            apply(m, f, [host, method, path_match, req_headers, injex])
          else
            injex
          end
        else
          :pass
        end
      end

      def get_injectors(), do: @injectors
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
