defmodule Faultex.HTTPoison do
  @moduledoc """
  HTTPoison wrapper that intercepts requests matching injector rules and
  returns injected responses instead of making real HTTP calls.
  """

  defmacro __using__(opts) do
    quote do
      @matcher __MODULE__

      use HTTPoison.Base
      use Faultex, unquote(opts)

      @impl HTTPoison.Base
      def request(method, url, body \\ "", headers \\ [], options \\ []) do
        request = %HTTPoison.Request{
          body: body,
          headers: headers,
          method: method,
          options: options,
          params: %{},
          url: url
        }

        request_name = "#{method} #{url}"

        case match(request) do
          {true, injector} ->
            injector_name = "#{inspect(injector.__struct__)} #{request_name}"
            Faultex.Reporter.report(injector_name, :started)
            resp = Faultex.inject(injector)
            Faultex.Reporter.report(injector_name, :finished)

            case resp.action do
              :reject ->
                {:error, %HTTPoison.Error{reason: :closed}}

              :passthrough ->
                super(method, url, body, headers, options)

              :response ->
                {:ok,
                 %HTTPoison.Response{
                   body: resp.body,
                   headers: resp.headers,
                   request: request,
                   request_url: url,
                   status_code: resp.status
                 }}

              :steal ->
                _ = super(method, url, body, headers, options)
                {:error, %HTTPoison.Error{reason: :closed}}
            end

          {false, _} ->
            Faultex.Reporter.report(request_name, :skipped)
            super(method, url, body, headers, options)
        end
      end

      def match(%HTTPoison.Request{
            method: method,
            headers: headers,
            url: url
          }) do
        req_headers = process_request_headers(headers)

        method = method |> to_string() |> String.upcase()
        %{host: host, path: path} = url |> URI.parse()

        path_info =
          (path || "/")
          |> String.split("/")
          |> Enum.reject(&match?("", &1))

        @matcher.match?(host, method, path_info, req_headers)
      end
    end
  end
end
