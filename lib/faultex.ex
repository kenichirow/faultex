defmodule Faultex do
  @moduledoc """

  ```elixir

  defmodule MyMatcher do
    use Faultex, injectors: [ 
      %Faultex{
       # Matches all requests.
        delay: 1_000,
      }
    ]
  end

  {true, %Faultex} = MyMatcher.match?("*", "GET", ["path", "to", "app"], [])

  ```

  ## Configulation

  You can pass these options to `use Faultex`

  - disable: if true, disable all injectors
  - injectors: list of Injectors 

  ### Injector

  In some parameters, you can set the `"*"`. 
  which means matches all incoming parameters.

  - disable: optional. if true, disable this injectors. if omit this parameter, set default to `false`
  - host: optioanl. matches request host. if omit this parameters, set default to `"*"` 
  - path: optional. matches pattern for request path. You can use Plug.Router style path parameters like `:id` and wildcard pattern like `/*path` default is `*`
  - methd: optional. metches request method. atom or string. default is `"*"`
  - header: optional. matches request headers. default is `[]`
  - percentage: optional. default is `100`.
  - resp_status: optional. 
  - resp_body: optional.
  - resp_headers: optional.
  - resp_handler: optional.
  - resp_delay: optioanl. default is `0`
  """

  defstruct [
    :id,
    :disable,
    :host,
    :method,
    :path_match,
    :headers,
    :percentage,
    :resp_status,
    :resp_headers,
    :resp_handler,
    :resp_body,
    :resp_delay,
  ]

  defmacro __before_compile__(env) do
    injectors = Module.get_attribute(env.module, :__faultex_injectors__)

    for injector <- Faultex.build_injectors(injectors) do
      host = injector.host
      method = injector.method
      path_match = injector.path_match
      headers = injector.headers
      percentage = injector.percentage
      disable = injector.disable

      quote do
        def match(
              unquote(to_underscore(host)),
              unquote(to_underscore(method)),
              unquote(to_underscore(path_match)),
              req_headers
            ) do
          disabled? = Application.get_env(:faultex, :disable, false) || unquote(disable)
          roll = Faultex.roll(unquote(percentage))
          match_headers? = Faultex.req_headers_match?(req_headers, unquote(headers))

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
        case match(host, method, path_match, req_headers) do
          %Faultex{} = injector ->
            injector

          _ ->
            host_match? = Faultex.host_match?(host, injector.host)
            method_match? = Faultex.method_match?(method, injector.method)
            path_match? = Faultex.path_match?(path_match, injector.path_match)
            req_headers_match? = Faultex.req_headers_match?(req_headers, injector.headers)

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
    end
  end

  def build_injectors(injectors) do
    injectors = Enum.map(injectors, &do_build_injector(&1))
    injectors ++ [%Faultex{disable: true}]
  end

  defp do_build_injector(injector_id) when is_atom(injector_id) do
    injector = Application.fetch_env!(:faultex, injector_id)

    path = Keyword.get(injector, :path, "*")
    host = Keyword.get(injector, :host, "*")
    method = Map.get(injector, :method, "*")
    headers = Keyword.get(injector, :headers) || []
    percentage = Keyword.get(injector, :percentage, 100)

    resp_body = Keyword.get(injector, :resp_body, "")
    resp_status = Keyword.get(injector, :resp_status, 200)
    resp_headers = Keyword.get(injector, :resp_headers, [])
    resp_handler = Keyword.get(injector, :resp_handler, nil)
    resp_delay = Keyword.get(injector, :resp_delay, 0)
    disable = Keyword.get(injector, :disable) || false

    {_, path_match} = build_path_match(path)

    %Faultex{
      id: injector,
      disable: disable,
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
    method = Map.get(injector, :method, "*")
    headers = Map.get(injector, :headers) || []
    percentage = Map.get(injector, :percentage, 100)

    resp_body = Map.get(injector, :resp_body, "")
    resp_status = Map.get(injector, :resp_status, 200)
    resp_headers = Map.get(injector, :resp_headers, [])
    resp_handler = Map.get(injector, :resp_handler, nil)
    resp_delay = Map.get(injector, :resp_delay, 0)
    disable = Map.get(injector, :disable) || false

    {_, path_match} = build_path_match(path)

    %Faultex{
      id: injector,
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
      disable: disable
    }
  end

  def build_path_params_match(params_matches, []) do
    params_matches
  end

  def build_path_params_match(params_matches, [var | rest]) when is_atom(var) do
    case Atom.to_string(var) do
      "_" <> _ ->
        build_path_params_match(params_matches, rest)

      key ->
        build_path_params_match([{key, {var, [], nil}} | params_matches], rest)
    end
  end

  def build_path_params_match(params_matches, [var | rest]) when is_binary(var) do
    case var do
      "_" <> _ ->
        build_path_params_match(params_matches, rest)

      _ ->
        build_path_params_match([{var, {String.to_atom(var), [], nil}} | params_matches], rest)
    end
  end

  def build_path_params_match(params_matches, rest) do
    build_path_params_match(params_matches, rest)
  end

  def build_path_match(path_pattern) do
    segments = path_pattern |> split() |> Enum.reverse()
    process_segment([], [], segments)
  end

  def split(path_pattern) do
    for seg <- String.split(path_pattern, "/"), seg != "" do
      seg
    end
  end

  def process_segment(vars, path_match, []) do
    {vars, path_match}
  end

  def process_segment(vars, path_match, ["*" <> seg | rest]) do
    key = String.to_atom(seg)
    process_segment([key | vars], [{:_, [], nil} | path_match], rest)
  end

  def process_segment(vars, path_match, [":" <> seg | rest]) do
    key = String.to_atom(seg)
    process_segment([key | vars], [{:_, [], nil} | path_match], rest)
  end

  def process_segment(vars, path_match, [seg | rest]) do
    process_segment(vars, [seg | path_match], rest)
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

  def req_headers_match?(_req_headers, []) do
    true
  end

  def req_headers_match?(_req_headers, nil) do
    true
  end

  def req_headers_match?(req_headers, headers) do
    Enum.all?(headers, fn header ->
      header in req_headers
    end)
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

  def roll(100), do: true
  def roll(percentage), do: :rand.uniform(100) < percentage
end
