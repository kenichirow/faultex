defmodule Injex.HTTPoison do
  use HTTPoison.Base

  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    request = %HTTPoison.Request{
      body: body,
      headers: headers,
      method: method,
      options: options,
      params: %{},
      url: url
    }

    # ここで実際にリクエストを送るか、送らないか
    case Injex.match(request) do
      %Injex{response: response, status: status} ->
        %HTTPoison.Response{
          body: response,
          headers: [],
          request: request,
          request_url: url,
          status_code: status
        }

      :pass ->
        super(method, url, body, headers, options)
    end
  end
end
