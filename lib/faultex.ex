defmodule Faultex do
  @moduledoc """
  """

  alias Faultex.Injector, as: Injector
  alias Faultex.Matcher, as: Matcher

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      injectors = Keyword.get(opts, :injectors, [])
      Module.put_attribute(__MODULE__, :__faultex_injectors__, injectors)
      @before_compile Matcher
    end
  end
end
