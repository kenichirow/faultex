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

  def inject(%Faultex.Injector.FaultInjector{} = injector) do
    Faultex.Injector.FaultInjector.inject(injector)
  end

  def inject(%Faultex.Injector.SlowInjector{} = injector) do
    Faultex.Injector.SlowInjector.inject(injector)
  end

  def inject(%Faultex.Injector.RejectInjector{} = injector) do
    Faultex.Injector.SlowInjector.inject(injector)
  end
end
