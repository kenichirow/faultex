defmodule Faultex do
  @moduledoc """
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
    :resp_delay
  ]

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      injectors = Keyword.get(opts, :injectors, [])
      Module.put_attribute(__MODULE__, :__faultex_injectors__, injectors)
      @before_compile Faultex.Matcher

      def match(host, method, path_match, req_headers, injector) do
        case match?(host, method, path_match, req_headers) do
          {true, %Faultex{}} = injector ->
            injector

          _ ->
            host_match? = Faultex.Matcher.host_match?(host, injector.host)
            method_match? = Faultex.Matcher.method_match?(method, injector.method)
            path_match? = Faultex.Matcher.path_match?(path_match, injector.path_match)
            req_headers_match? = Faultex.Matcher.req_headers_match?(req_headers, injector.headers)

            disabled? =
              Application.get_env(:injector, :disable, false) ||
                (Map.get(injector, :disable) || false)

            roll = Faultex.Matcher.roll(injector.percentage)

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
