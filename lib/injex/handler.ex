defmodule Injex.Handler do
  def handle_response(host, method, path_match, headers, injex) do
    IO.inspect "HANDLER"
    injex
  end
end
