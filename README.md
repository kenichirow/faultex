# ex_fit

![ci](https://github.com/kenichirow/ex_fit/actions/workflows/main.yml/badge.svg)

ExFit is a simple Elixir fault injection library.


## ExFit.Plug

リクエストを受ける側の特定のURL、メソッド、ヘッダー、確率が一致した場合にエラーレスポンスをクライアントに返す


```
 config :ex_fit, 
   disable: true,
   injectors: [RegisterFailure]
     
 config :ex_fit, RegisterFailure
   # Request matcher parameters
   host: "example.com"
   path: "/das/auth/*/*/register",
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
  use Plug
  plug ExFit.Plug.Http
end
```

config.exsのinjectorsを使わずにplugのオプションに指定することもできる
<注意> config.exs で設定した方が正規表現ではなく関数のパターンマッチが使われるので高速です

```
plug ExFit.Plug.Http, [
    status: 404,
    handlers: {MyApp.FailureHandler, 1},
    reposense: "404 not found",
    percentage: 100
]
```

## ExFit.HTTPoison

外部へのリクエストが特定のURL、メソッド、ヘッダー、確率が一致した場合にエラーレスポンスをクライアントに返す
マッチした場合リクエストは中断されレスポンスのみが返る
モックとして使うこともできる。

```
res = ExFit.HTTPoison.request!(:post, path, body, headers)
```


### Global parameters

- disable disable all injectors
- injectors list of injectors 

### Match parameters
- disable disable this injectors
- host: エラーにマッチするホスト 基本的に外部サービスとの通信でエラーを起こしたい場合に ExFit.HTTPoison へ渡すFault に使用する 省略可能
- path: エラーにマッチするURLのパターン 省略可能 ワイルドカード(*)でのマッチが使える
- methd: エラーにマッチするメソッド 省略可能
- exact: URLの完全一致でのみエラーにする 省略可能
- header: エラーにマッチするヘッダー 省略不可能
- percentage: パターンにマッチしたリクエストのうち何パーセントをエラーにするか

### Response parameters
- resp_status: エラーパターンにマッチした場合に返すhttpステータス
- resp_body: エラーパターンにマッチした場合に返すレスポンス 固定値のみ返せる
- resp_handler: レスポンスを返すmf 引数は１つ(connが渡ってくる) このオプションがある場合はresponseは使われない リクエスト内容に応じたエラーを返したい場合はこれを使う
- resp_delay: レスポンスを返すまでに遅延させる値(ms)

## Manual Fault injection



グローバルの設定にマッチする ExFit.match/1

```
if ExFit.match?(conn) do
  raise MyApp.Error
end
```

引数の設定パターンにマッチする ExFit.match?/2

```
pattern = [
  headers: [{"X-Fault-Inject", "not-found"}],
]

# raw config name aliases
if ExFit.matches?(conn, pattern) do
  raise MyApp.Error
end

# config name aliases
if ExFit.matches?(conn, :not_found_on_request) do
  raise MyApp.Error
end
```

## TODO

- [x] Allow :resp_headers key.
- [x] Allow :resp_delay key.
- [x] Allow :percentage key.
- [x] :headers are should parse list (cowboy style headers) [{key, value}].
- [] Allow response handlers
- [] Allow Runtime configure
 - Injex.Router should have __using__ macro and compile routes dinamicaly
- [] Disaced config.exs
- [] - Disable path parameters warning "/:foo/:bar".
