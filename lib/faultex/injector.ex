defmodule Faultex.Injector do
  @moduledoc """
  Common module for fault injectors
  """

  @__fields__ [:id, :disable, :host, :method, :path, :headers, :percentage]

  defmacro __using__(_) do
    fields = @__fields__

    quote do
      @__fields__ unquote(fields)
    end
  end

  @spec inject(struct()) :: Faultex.Response.t()
  def inject(injector), do: injector.__struct__.inject(injector)
end
