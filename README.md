# Faultex

![ci](https://github.com/kenichirow/faultex/actions/workflows/main.yml/badge.svg)

Faultex is a simple Elixir fault injection library.

## USAGE

Faultex can be use with the Plug and HTTPoison


### Faultex.Plug

Add the :faultex to your project's mix.exs:

```
defp deps do
  [
    {:plug, "~> 1.0"},
    {:faultex, "~> 0.1"}
  ]
end
```

```elixir
  defmodule MyRouter do
    use Faultex.Plug, injectors: [
     %Faultex.Injector.SlowInjector{
      path: "/test/*/bar",
      headers: [{"X-Fault-Inject", "auth-failed"}],
      percentage: 100,
      resp_delay: 1000
     }
    ]
     
    get "test/:foo/bar" do
      ...
    end
  end
```

```bash
curl 
> res
```


### Faultex.HTTPoison

Add the :faultex to your project's mix.exs:

```
defp deps do
  [
    {:httpoison, "~> 1.0"},
    {:faultex, "~> 0.1"}
  ]
end
```

```elixir
defmodule MyApp.HTTPoison do
  use Faultex.HTTPoison, injectors: [
     %Faultex.Injector.ErrorInjector{
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

alias MyApp.HTTPoison as HTTPoison

# receive 401
res = HTTPoison.request!(:get, "test/foo/bar", body, headers)

> res%{
}
```


## Use config.exs

```elixir
 config :faultex, 
   injectors: [{:register_fail, Faultex.Injector.ErrorInjector}]
     
 config :faultex, :register_fail 
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
use Faultex.HTTPoison, Application.compile_env!(faultex, :injectors)
```

### Global Parameters

- disable: if true, disable all injectors
- injectors: list of injectors 

### Fault Injector Configuration

In some request match parameters, you can set `"*"`. 
which means matches all incoming parameters.

- disable: optional. if true, disable this injectors. if omit this parameter, set default to `false`
- host: optioanl. matches request host. if omit this parameters, set default to `"*"` 
- path: optional. matches pattern for request path. You can use Plug.Router style path parameters like `:id` and wildcard pattern like `/*path` default is `*`
- methd: optional. metches request method. atom or string. default is `"*"`
- header: optional. matches request headers. default is `[]`
- percentage: optional. default is `100`.
- resp_status: optional. 
- resp_body: optional.
- resp_headers: optional.
- resp_handler: optioanl.
- resp_delay: optioanl.

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
- [x] match/5 check request path pattern
- [x] match/4, match/5 returns {:ok, true, %Faultex} | {:ok, false, nil}
- [] debug log
- [] example project
- [] Injecror to Behaviour
