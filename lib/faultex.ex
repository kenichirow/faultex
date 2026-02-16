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

  @spec inject(
          Faultex.Injector.ErrorInjector.t()
          | Faultex.Injector.SlowInjector.t()
          | Faultex.Injector.RejectInjector.t()
          | Faultex.Injector.RandomInjector.t()
          | Faultex.Injector.ChainInjector.t()
        ) :: Faultex.Response.t()
  def inject(%Faultex.Injector.ErrorInjector{} = injector) do
    Faultex.Injector.ErrorInjector.inject(injector)
  end

  def inject(%Faultex.Injector.SlowInjector{} = injector) do
    Faultex.Injector.SlowInjector.inject(injector)
  end

  def inject(%Faultex.Injector.RejectInjector{} = injector) do
    Faultex.Injector.RejectInjector.inject(injector)
  end

  def inject(%Faultex.Injector.RandomInjector{} = injector) do
    Faultex.Injector.RandomInjector.inject(injector)
  end

  def inject(%Faultex.Injector.ChainInjector{} = injector) do
    Faultex.Injector.ChainInjector.inject(injector)
  end
end
