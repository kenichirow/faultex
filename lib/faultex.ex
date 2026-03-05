defmodule Faultex do
  @moduledoc """
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      injectors = Keyword.get(opts, :injectors, [])
      Module.put_attribute(__MODULE__, :__faultex_injectors__, injectors)
      @before_compile Faultex.Matcher
    end
  end

  @spec inject(struct()) :: Faultex.Response.t()
  def inject(injector) do
    resp = Faultex.Injector.inject(injector)

    case Application.get_env(:faultex, :reporter) do
      nil -> :ok
      reporter -> reporter.report(:injected, injector, %{response: resp})
    end

    resp
  end
end
