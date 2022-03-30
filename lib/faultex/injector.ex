defmodule Faultex.Injector do
  defstruct [
    :id,
    :disable,
    :host,
    :method,
    :path,
    :headers,
    :percentage,
    :resp_status,
    :resp_headers,
    :resp_handler,
    :resp_body,
    :resp_delay
  ]
end
