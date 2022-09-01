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

    match_fns =
      for {{host_match, method_match, path_match}, clauses} <- Faultex.Matcher.build_matchers(injectors) do
        escaped_clauses = Macro.escape(clauses)

        quote do
          def match?(
                unquote(to_underscore(host_match)),
                unquote(to_underscore(method_match)),
                unquote(to_underscore(path_match)),
                req_headers
              ) do
            case Faultex.Matcher.select_injector(req_headers, unquote(escaped_clauses)) do
              nil ->
                {false, nil}

              {matcher, injector} ->
                disabled? = Application.get_env(:faultex, :disable, false) || matcher.disable
                roll = Faultex.Matcher.roll(matcher.percentage)

                if roll and not disabled? do
                  {true, injector}
                else
                  {false, nil}
                end
            end
          end
        end
      end

    catch_all =
      quote do
        def match?(_, _, _, _), do: {false, nil}
      end

    match_fns ++ [catch_all]
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
    group_by_match(matchers)
  end

  def group_by_match(matchers) do
    matchers
    |> Enum.group_by(fn {matcher, _injector} ->
      {matcher.host_match, matcher.method_match, matcher.path_match}
    end)
  end

  def do_build_matcher(injector_id) when is_atom(injector_id) do
    do_build_matcher(Application.fetch_env!(:faultex, injector_id))
  end

  def do_build_matcher(injector) when is_struct(injector, Faultex.Injector.FaultInjector) do
    resp_body = Map.get(injector, :resp_body) || ""
    resp_status = Map.get(injector, :resp_status) || 200
    resp_headers = Map.get(injector, :resp_headers) || []
    resp_handler = Map.get(injector, :resp_handler) || nil
    resp_delay = Map.get(injector, :resp_delay) || 0

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

  def do_build_matcher(injector) when is_struct(injector, Faultex.Injector.SlowInjector) do
    {
      fill_matcher_params(injector),
      %Faultex.Injector.SlowInjector{
        resp_delay: Map.get(injector, :resp_delay, 0)
      }
    }
  end

  def do_build_matcher(injector) when is_struct(injector, Faultex.Injector.RejectInjector) do
    {
      fill_matcher_params(injector),
      %Faultex.Injector.RejectInjector{
        resp_delay: Map.get(injector, :resp_delay, 0)
      }
    }
  end

  def do_build_matcher(injector) when is_map(injector) do
    resp_body = Map.get(injector, :resp_body) || ""
    resp_status = Map.get(injector, :resp_status) || 200
    resp_headers = Map.get(injector, :resp_headers) || []
    resp_handler = Map.get(injector, :resp_handler) || nil
    resp_delay = Map.get(injector, :resp_delay) || 0

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

  def select_injector(req_headers, clauses) do
    Enum.find(clauses, fn({matcher, _injector}) ->
      Faultex.Matcher.req_headers_match?(req_headers, matcher.headers)
    end)
  end

  def roll(100), do: true
  def roll(percentage), do: :rand.uniform(100) < percentage
end
