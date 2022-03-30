defmodule Faultex do
  @moduledoc """
  """

  alias Faultex.Injector, as: Injector
  alias Faultex.Matcher, as: Matcher

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      injectors = Keyword.get(opts, :injectors, [])
      Module.put_attribute(__MODULE__, :__faultex_injectors__, injectors)
      @before_compile Matcher

      def match(host, method, path_match, req_headers, injector) do
        case match?(host, method, path_match, req_headers) do
          {true, %Injector{}} = injector ->
            injector

          _ ->
            host_match? = Matcher.host_match?(host, injector.host)
            method_match? = Matcher.method_match?(method, injector.method)
            path_match? = Matcher.path_match?(path_match, injector.path)
            req_headers_match? = Matcher.req_headers_match?(req_headers, injector.headers)

            disabled? =
              Application.get_env(:injector, :disable, false) ||
                (Map.get(injector, :disable) || false)

            roll = Matcher.roll(injector.percentage)

            if host_match? and method_match? and path_match? and req_headers_match? and
                 not disabled? and roll do
              {true, injector}
            else
              {false, nil}
            end
        end
      end
    end
  end
end
