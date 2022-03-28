# Faultex

![ci](https://github.com/kenichirow/faultex/actions/workflows/main.yml/badge.svg)

Faultex is simple Fault injection library.


## Installation

```
defp deps do
  [
    {:plug, "~> 1.0"},
    {:httpoison, "~> 1.0"},
    {:faultex, "~> 0.1"}
  ]
end
```

## Usage

### Configure via Faultex.Plug Options

Add Faultex.Plug to your application's Router

```elixir
  defmodule MyRouter do
    use Faultex.Plug, injectors: [
     %{
      path: "/test/*/bar",
      method: "GET",
      headers: [{"X-Fault-Inject", "auth-failed"}],
      percentage: 100,
      resp_status: 401,
      resp_body: Jason.encode!(%{message: "Autharization failed"}),
      resp_headers: [],
      resp_delay: 1000
     }
    ]
  end
```


###  Use config.exs

```elixir
 config :faultex, 
   injectors: [RegisterFailure]
     
 config :faultex, RegisterFailure
   # Request matcher parameters
   host: "example.com"
   path: "/auth/*/*/register",
   method: "POST",
   exact: true,
   header: {"X-Fault-Inject", "auth-failed"},
   percentage: 100,

   # Response parameters
   resp_status: 401,
   resp_handler: MyApp.FailureHandler,
   resp_body: Jason.encode!(%{message: "Autharization failed"}),
   resp_headers: [],
   resp_delay: 1000
```

```elixir
  defmodule MyRouter do
    use Faultex.Plug, Application.compile_env!(faultex, :injectors)
  end
```

## TODO

- [x] Allow :resp_headers key.
- [x] Allow :resp_delay key.
- [x] Allow :percentage key.
- [x] :headers are should parse list (cowboy style headers) [{key, value}].
- [x] Allow response handlers
- [x] Disaced config.exs
- [x] Faultex.Plug and Faultex.HTTPoison are should have __using__ macro and compile routes dinamicaly
- [x] Allow :disable key.
- [] Allow :exact key.
- [] - pass the path parameters to resp_handler
- [] match/5 check request path pattern
- [] match/4, match/5 returns {:ok, true, %Faultex} | {:ok, false, nil}
- [] debug log
- [] example project
