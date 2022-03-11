defmodule Injex do
  @moduledoc """
  """

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

  defmacro __before_compile__(env) do
    injectors = Module.get_attribute(env.module, :injectors)

    for config <- Injex.build_matchers(injectors) do
      host = config.host
      method = config.method
      path_match = config.path_match
      headers = config.headers
      resp_handler = config.resp_handler
      percentage = config.percentage

      quote do
        def match(
              unquote(wildcard_to_underscore(host)),
              unquote(wildcard_to_underscore(method)),
              unquote(path_match),
              req_headers
            ) do
          disabled? = Application.get_env(:injex, :disable, false)
          roll = Injex.roll(unquote(percentage))
          match_headers? = Injex.match_req_headers?(req_headers, unquote(headers))

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
      @before_compile Injex

      def match(host, method, path_match, req_headers, injex) do
        # TODO host, method, path, headers のマッチをやる
        disabled? = Application.get_env(:injex, :disable, false)
        roll = Injex.roll(injex.percentage)
        match_headers? = Injex.match_req_headers?(req_headers, injex.headers)

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

      {vars, path_match} = Plug.Router.Utils.build_path_match(path)
      params_match = Plug.Router.Utils.build_path_params_match(vars)

      %Injex{
        id: "",
        host: host,
        method: method,
        path_match: path_match,
        percentage: percentage,
        headers: headers,
        resp_status: resp_status,
        resp_body: resp_body,
        resp_headers: resp_headers,
        resp_handler: resp_handler,
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

  def wildcard_to_underscore("*") do
    quote do: _
  end

  def wildcard_to_underscore(any) do
    any
  end

  def create_match(_, _, _, _, _, %Injex{pass: true}) do
    quote location: :keep do
      def match(_host, _method, _, _req_headers) do
        :pass
      end
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
