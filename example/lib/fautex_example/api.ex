defmodule Faultex.Api do
  use Faultex.Plug, injectors: [
    %Faultex.Injector.ErrorInjector{
      path: "/example1",
      headers: [{"x-example-fault-inject","true"}],
      resp_body: "request failed"
    },
    %Faultex.Injector.SlowInjector{
      path: "/example2",
      percentage: 50,
      resp_delay: 2000
    }
  ]

  plug(:match)
  plug(:dispatch)

  get "/example1" do
     send_resp(conn, 200, "OK")
  end

  get "/example2" do
     send_resp(conn, 200, "OK")
  end
end
