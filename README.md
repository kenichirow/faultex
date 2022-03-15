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
     [
      path: "/test/*/bar",
      method: "GET",
      headers: [{"X-Fault-Inject", "auth-failed"}],
      percentage: 100,
      resp_status: 401,
      resp_body: Jason.encode!(%{message: "Autharization failed"}),
      resp_headers: [],
      resp_delay: 1000
     ],
     [
      path: "/test/*/bar",
      method: "GET",
      headers: [{"X-Fault-Inject", "auth-failed"}],
      percentage: 100,
      resp_status: 401,
      resp_body: Jason.encode!(%{message: "Autharization failed"}),
      resp_headers: [],
      resp_delay: 1000
     ]
    ]
     
    get "test/:foo/bar" do
      # returns 401 to client
      # never call this route
      ...
    end
  end
```

```bash
curl 
> res
```


### Faultex.HTTPoison

Add the :ex_fit to your project's mix.exs:

```
defp deps do
  [
    {:httpoison, "~> 1.0"},
    {:ex_fit, "~> 0.1"}
  ]
end
```

```elixir
defmodule MyApp.HTTPoison do
  use Injex.HTTPoison, injectors: [
      path: "/test/*/bar",
      method: "GET",
      headers: [{"X-Fault-Inject", "auth-failed"}],
      percentage: 100,
      resp_status: 401,
      resp_body: Jason.encode!(%{message: "Autharization failed"}),
      resp_headers: [],
      resp_delay: 1000
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
 config :ex_fit, 
   injectors: [RegisterFailure]
     
 config :ex_fit, RegisterFailure
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
use Faultex.HTTPoison, Application.compile_env!(ex_fit, :injectors)
```

### Global Parameters

- disable disable all injectors
- injectors list of injectors 

### Fault Injector Configuration

- disable disable this injectors
- host: default is `"*"`
- path: default is `"*`
- methd: エラーにマッチするメソッド 省略可能
- exact: URLの完全一致でのみエラーにする 省略可能
- header: エラーにマッチするヘッダー 省略不可能
- percentage: パターンにマッチしたリクエストのうち何パーセントをエラーにするか
- resp_status: エラーパターンにマッチした場合に返すhttpステータス
- resp_body: エラーパターンにマッチした場合に返すレスポンス 固定値のみ返せる
- resp_handler: レスポンスを返すmf 引数は１つ(connが渡ってくる) このオプションがある場合はresponseは使われない リクエスト内容に応じたエラーを返したい場合はこれを使う
- resp_delay: レスポンスを返すまでに遅延させる値(ms)

## TODO

- [x] Allow :resp_headers key.
- [x] Allow :resp_delay key.
- [x] Allow :percentage key.
- [x] :headers are should parse list (cowboy style headers) [{key, value}].
- [x] Allow response handlers
- [x] Disaced config.exs
- [x] Injex.Plug and Injex.HTTPoison are should have __using__ macro and compile routes dinamicaly
- [x] Allow :disable key.
- [] Allow :exact key.
- [] - pass the path parameters to resp_handler
- [] Injex.match returns {:ok, true, %Injex.Response{}}
