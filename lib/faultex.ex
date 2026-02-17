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

  @spec inject(Faultex.Injector.t()) :: Faultex.Response.t()
  def inject(injector) do
    Faultex.Injector.inject(injector)
  end
end
