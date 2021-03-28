defmodule Injex.HTTPoison do
  use HTTPoison.Base

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
      %Injex{response: response, status: status} ->
        {:ok,
         %HTTPoison.Response{
           body: response,
           headers: [],
           request: request,
           request_url: url,
           status_code: status
         }}

      :pass ->
        super(method, url, body, headers, options)
    end
  end

  def match(%HTTPoison.Request{
        method: method,
        headers: headers,
        url: url
      }) do
    req_headers = HTTPoison.process_request_headers(headers)

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
      path
      |> String.split("/")
      |> Enum.reject(&match?("", &1))

    Injex.match(host, method, path_info, req_headers)
  end
end
