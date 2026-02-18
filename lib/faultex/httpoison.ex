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

        case match(request) do
          {true, injector} ->
            resp = Faultex.inject(injector)

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
