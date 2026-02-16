defmodule Faultex.Response do
  @moduledoc """
  Response struct returned by injectors
  """

  @type t :: %__MODULE__{
          status: integer() | nil,
          headers: [{String.t(), String.t()}] | nil,
          body: String.t() | nil
        }

  defstruct [:status, :headers, :body]
end
