defmodule Faultex.Handler do
  @spec handle_response(String.t(), String.t(), list(), [{String.t(), String.t()}], term()) ::
          Faultex.Injector.FaultInjector.t()
  def handle_response(_host, _method, _path_match, _headers, _faultex) do
    %Faultex.Injector.FaultInjector{
      resp_status: 400,
      resp_headers: [{"x-faultex", "failed"}],
      resp_body: "request_failed"
    }
  end
end
