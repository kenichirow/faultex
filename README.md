# Faultex

![ci](https://github.com/kenichirow/faultex/actions/workflows/main.yml/badge.svg)

Faultex is a simple Elixir fault injection library. Inspired by [go-fault](https://github.com/lingrino/go-fault).

## Installation

Add `:faultex` to your project's `mix.exs`:

```elixir
defp deps do
  [
    {:faultex, "~> 0.1"}
  ]
end
```

## Injector Types

| Injector | Description | Response Parameters |
|---|---|---|
| `Faultex.Injector.ErrorInjector` | Returns an error response immediately | `resp_status`, `resp_body`, `resp_headers`, `resp_delay` |
| `Faultex.Injector.SlowInjector` | Delays the request, then passes through to the original handler | `resp_delay` |
| `Faultex.Injector.RejectInjector` | Aborts the connection with an empty response | (none) |

## Usage: Faultex.Plug

```elixir
defmodule MyRouter do
  use Faultex.Plug, injectors: [
    %Faultex.Injector.ErrorInjector{
      path: "/api/*/users",
      headers: [{"x-fault-inject", "true"}],
      percentage: 100,
      resp_status: 500,
      resp_body: "Internal Server Error"
    },
    %Faultex.Injector.SlowInjector{
      path: "/api/health",
      percentage: 50,
      resp_delay: 2000
    }
  ]

  plug(:match)
  plug(:dispatch)

  get "/api/:version/users" do
    send_resp(conn, 200, "OK")
  end

  get "/api/health" do
    send_resp(conn, 200, "OK")
  end
end
```

## Usage: Faultex.HTTPoison

```elixir
defmodule MyApp.HTTPClient do
  use Faultex.HTTPoison, injectors: [
    %Faultex.Injector.ErrorInjector{
      path: "/api/*/users",
      method: "GET",
      headers: [{"x-fault-inject", "true"}],
      percentage: 100,
      resp_status: 401,
      resp_body: ~s({"message": "Authorization failed"}),
      resp_headers: []
    }
  ]
end
```

```elixir
alias MyApp.HTTPClient

# When the request matches, returns injected 401 response
{:ok, resp} = HTTPClient.get("https://example.com/api/v1/users", [{"x-fault-inject", "true"}])
resp.status_code  #=> 401
```

## Configuration

### Request Match Parameters

All injector types share these parameters for matching incoming requests:

- `disable` — if `true`, disables this injector. Default: `false`
- `host` — matches request host. Default: `"*"` (matches all)
- `path` — matches request path pattern. Supports wildcard `*` and Plug.Router-style parameters like `:id`. Default: `"*"`
- `method` — matches request method (e.g. `"GET"`, `"POST"`). Default: `"*"` (matches all)
- `headers` — matches request headers. List of `{key, value}` tuples. Default: `[]`
- `percentage` — probability (0–100) that the injector fires. Default: `100`

### Response Parameters

#### ErrorInjector

- `resp_status` — HTTP status code. Default: `200`
- `resp_body` — response body string. Default: `""`
- `resp_headers` — list of `{key, value}` header tuples. Default: `[]`
- `resp_delay` — delay in milliseconds before returning the response. Default: `0`

#### SlowInjector

- `resp_delay` — delay in milliseconds before passing through to the original handler. Default: `0`

#### RejectInjector

No additional response parameters. Returns an empty response.

### Global Configuration

You can disable all injectors at runtime via application config:

```elixir
Application.put_env(:faultex, :disable, true)
```

## TODO

- [ ] Allow `:exact` key
- [ ] Pass path parameters to resp_handler
- [ ] Debug log
- [ ] RejectInjector
