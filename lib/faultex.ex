defmodule Faultex do
  @moduledoc """
  Fault injection library for Elixir. Inspired by [go-fault](https://github.com/lingrino/go-fault).

  Faultex intercepts HTTP requests at the Plug or HTTPoison layer and injects
  configurable faults (errors, delays, rejections) based on matching rules.

  Injector rules are compiled into pattern-matching functions at compile time
  via `@before_compile`. At runtime, incoming requests are matched against
  these functions to determine whether a fault should be injected.

  ## Integration

    * `Faultex.Plug` — Plug middleware integration
    * `Faultex.HTTPoison` — HTTPoison client wrapper

  ## Configuration

  Disable all injectors at runtime:

      Application.put_env(:faultex, :disable, true)
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
    Faultex.Injector.inject(injector)
  end
end
