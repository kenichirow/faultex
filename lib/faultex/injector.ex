defprotocol Faultex.Injector do
  @moduledoc """
  Protocol for fault injectors
  """

  @spec inject(t) :: Faultex.Response.t()
  def inject(injector)
end
