defmodule Faultex.Injector do
  @moduledoc """
  Behaviour for fault injectors
  """

  @callback inject(request :: term()) :: Faultex.Response.t()
end
