defmodule Faultex.Response do
  @moduledoc """
  Response struct returned by injectors
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
