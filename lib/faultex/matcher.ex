defmodule Faultex.Matcher do
  @moduledoc """
  """

  defstruct [
    :disable,
    :host_match,
    :method_match,
    :path_match,
    :headers,
    :percentage
  ]

  defmacro __before_compile__(env) do
    injectors = Module.get_attribute(env.module, :__faultex_injectors__)

    for {matcher, injector} <- Faultex.Matcher.build_matchers(injectors) do
      host_match = matcher.host_match
      method_match = matcher.method_match
      path_match = matcher.path_match
      headers = matcher.headers
      percentage = matcher.percentage
      disable = matcher.disable

      quote do
        def match?(
              unquote(to_underscore(host_match)),
              unquote(to_underscore(method_match)),
              unquote(to_underscore(path_match)),
              req_headers
            ) do
          disabled? = Application.get_env(:faultex, :disable, false) || unquote(disable)
          roll = Faultex.Matcher.roll(unquote(percentage))
          match_headers? = Faultex.Matcher.req_headers_match?(req_headers, unquote(headers))

          if roll and not disabled? and match_headers? do
            {true, unquote(Macro.escape(injector))}
          else
            {false, nil}
          end
        end
      end
    end
  end

  defp fill_matcher_params(injector) do
    path = Map.get(injector, :path, "*")
    host = Map.get(injector, :host, "*")
    method = Map.get(injector, :method, "*")
    headers = Map.get(injector, :headers) || []
    percentage = Map.get(injector, :percentage, 100)
    {_, path_match} = build_path_match(path)
    disable = Map.get(injector, :disable) || false

    %Faultex.Matcher{
      host_match: host,
      method_match: method,
      path_match: path_match,
      percentage: percentage,
      headers: headers,
      disable: disable
    }
  end

  def build_matchers(injectors) do
    matchers = Enum.map(injectors, &do_build_matcher(&1))
    matchers ++ [{%Faultex.Matcher{disable: true}, %Faultex.Injector.FaultInjector{}}]
  end

  defp do_build_matcher(injector_id) when is_atom(injector_id) do
    do_build_matcher(Application.fetch_env!(:faultex, injector_id))
  end

  defp do_build_matcher(injector) when is_struct(injector, Faultex.Injector.FaultInjector) do
    resp_body = Map.get(injector, :resp_body, "")
    resp_status = Map.get(injector, :resp_status, 200)
    resp_headers = Map.get(injector, :resp_headers, [])
    resp_handler = Map.get(injector, :resp_handler, nil)
    resp_delay = Map.get(injector, :resp_delay, 0)

    {
      fill_matcher_params(injector),
      %Faultex.Injector.FaultInjector{
        resp_status: resp_status,
        resp_body: resp_body,
        resp_headers: resp_headers,
        resp_delay: resp_delay,
        resp_handler: resp_handler
      }
    }
  end

  defp do_build_matcher(injector) when is_struct(injector, Faultex.Injector.SlowInjector) do
    {
      fill_matcher_params(injector),
      %Faultex.Injector.SlowInjector{
        resp_delay: Map.get(injector, :resp_delay, 0)
      }
    }
  end

  defp do_build_matcher(injector) when is_struct(injector, Faultex.Injector.RejectInjector) do
    {
      fill_matcher_params(injector),
      %Faultex.Injector.RejectInjector{
        resp_delay: Map.get(injector, :resp_delay, 0)
      }
    }
  end

  defp do_build_matcher(injector) when is_map(injector) do
    resp_body = Map.get(injector, :resp_body, "")
    resp_status = Map.get(injector, :resp_status, 200)
    resp_headers = Map.get(injector, :resp_headers, [])
    resp_handler = Map.get(injector, :resp_handler, nil)
    resp_delay = Map.get(injector, :resp_delay, 0)

    {
      fill_matcher_params(injector),
      %Faultex.Injector.FaultInjector{
        resp_status: resp_status,
        resp_body: resp_body,
        resp_headers: resp_headers,
        resp_delay: resp_delay,
        resp_handler: resp_handler
      }
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
