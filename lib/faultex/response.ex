defmodule Faultex.Response do
  @moduledoc """
  Response struct returned by injectors.

  ## Actions

    * `:response` — send an injected error response and halt
    * `:passthrough` — continue to the original handler (used by SlowInjector after delay)
    * `:reject` — halt the connection without sending a response
    * `:steal` — let the request proceed but kill the process before the response reaches the client
  """

  @type action :: :response | :passthrough | :reject | :steal

  @type t :: %__MODULE__{
          action: action(),
          status: integer() | nil,
          headers: [{String.t(), String.t()}] | nil,
          body: String.t() | nil
        }

  defstruct [:action, :status, :headers, :body]
end
