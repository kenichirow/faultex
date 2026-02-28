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

  @doc """
  Applies the configured delay before returning.
  """
  @spec apply_delay(struct()) :: :ok
  def apply_delay(injector) do
    case Map.get(injector, :resp_delay) do
      nil -> :ok
      0 -> :ok
      delay when is_integer(delay) and delay > 0 -> Process.sleep(delay)
    end
  end
end
