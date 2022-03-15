defmodule Faultex.Handler do
  def handle_response(host, method, path_match, headers, injex) do
    %Faultex{
      resp_status: 400,
      resp_headers: [{"x-injex", "failed"}],
      resp_body: "request_failed"
    }
  end
end
