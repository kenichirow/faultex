defmodule Faultex do
  @moduledoc """
    # Faultex

   ### Global Parameters
   
   - disable: if true, disable all injectors
   - injectors: list of injectors 
   
   ### Fault Injector Configuration
   
   In some request match parameters, you can set `"*"`. 
   which means matches all incoming parameters.
   
   - disable: optional. if true, disable this injectors. if omit this parameter, set default to `false`
   - host: optioanl. matches request host. if omit this parameters, set default to `"*"` 
   - path: optional. matches pattern for request path. You can use Plug.Router style path parameters like `:id` and wildcard pattern like `/*path` default is `*`
   - methd: optional. metches request method. atom or string. default is `"*"`
   - header: optional. matches request headers. default is `[]`
   - percentage: optional. default is `100`.
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
