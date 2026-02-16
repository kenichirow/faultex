defmodule Faultex.HTTPoison do
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

            {:ok,
             %HTTPoison.Response{
               body: resp.body,
               headers: resp.headers,
               request: request,
               request_url: url,
               status_code: resp.status
             }}

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

        method =
          case method do
            method when is_atom(method) ->
              Atom.to_string(method)

            method ->
              method
          end

        method = method |> String.upcase() |> to_string()
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
