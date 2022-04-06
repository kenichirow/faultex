defmodule FaultexExample.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Faultex.Api, options: [port: 4040]}
    ]

    opts = [strategy: :one_for_one, name: FaultexExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
