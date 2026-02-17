defmodule Faultex.Injector do
  @moduledoc """
  Common module for fault injectors
  """

  @common_fields [:id, :disable, :host, :method, :path, :headers, :percentage]

  defmacro __using__(opts) do
    extra_fields = Keyword.get(opts, :fields, [])
    all_fields = @common_fields ++ extra_fields

    quote do
      defstruct unquote(all_fields)
    end
  end

  @spec inject(struct()) :: Faultex.Response.t()
  def inject(injector), do: injector.__struct__.inject(injector)
end
