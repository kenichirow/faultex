defmodule Faultex.Handler do
  def handle_response(host, method, path_match, headers, faultex) do
    %Faultex.Injector.FaultInjector{
      resp_status: 400,
      resp_headers: [{"x-faultex", "failed"}],
      resp_body: "request_failed"
    }
  end
end
