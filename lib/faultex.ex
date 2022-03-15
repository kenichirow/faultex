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

    for config <- Faultex.build_matchers(injectors) do
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
  def build_matchers(injectors) do
    Enum.map(injectors, fn config ->
      path = Map.get(config, :path, "*")
      host = Map.get(config, :host, "*")
      method = Map.get(config, :method, "GET")
      headers = Map.get(config, :headers, [])
      percentage = Map.get(config, :percentage, 100)

      resp_body = Map.get(config, :resp_body, "")
      resp_status = Map.get(config, :resp_status, 200)
      resp_headers = Map.get(config, :resp_headers, [])
      resp_handler = Map.get(config, :resp_handler, nil)
      resp_delay = Map.get(config, :resp_delay, 0)
      disable = Map.get(config, :disable, false)

      {vars, path_match} = Plug.Router.Utils.build_path_match(path)
      params_match = Plug.Router.Utils.build_path_params_match(vars)

      %Faultex{
        id: "",
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
        resp_handler: resp_handler,
      }
    end) ++
      [
        %Faultex{
          disable: true
        }
      ]
  end

  def to_underscore(nil) do
    quote do: _
  end

  def to_underscore("*") do
    quote do: _
  end

  def to_underscore(any) do
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
