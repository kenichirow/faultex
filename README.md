# ex_fit

ExFit is a simple Plug based fault injection tool.

![ci](https://github.com/kenichirow/ex_fit/actions/workflows/main.yml/badge.svg)

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
     percent: 100,

     # Response parameters
     resp_status: 401,
     resp_handler: MyApp.FailureHandler,
     resp_body: Jason.encode!(%{message: "Autharization failed"}),
     resp_headers: [],
     resp_delay: 1000
```

Injector のパラメータ 

- host: エラーにマッチするホスト 基本的に外部サービスとの通信でエラーを起こしたい場合に ExFit.HTTPoison へ渡すFault に使用する 省略可能
- path: エラーにマッチするURLのパターン 省略可能 ワイルドカード(*)でのマッチが使える
- methd: エラーにマッチするメソッド 省略可能
- exact: URLの完全一致でのみエラーにする 省略可能
- header: エラーにマッチするヘッダー 省略不可能
- percent: パターンにマッチしたリクエストのうち何パーセントをエラーにするか

- resp_status: エラーパターンにマッチした場合に返すhttpステータス
- resp_body: エラーパターンにマッチした場合に返すレスポンス 固定値のみ返せる
- resp_handler: レスポンスを返すmf 引数は１つ(connが渡ってくる) このオプションがある場合はresponseは使われない リクエスト内容に応じたエラーを返したい場合はこれを使う
- resp_delay: レスポンスを返すまでに遅延させる値(ms)


## ExFit.Plug

リクエストを受ける側でエラーにしたい場合に使用する

```
plug ExFit.Plug.Http
```

オプションで上書きできる特定のPhoenixControllerのみでエラーを起こしたい場合は

```
plug ExFit.Plug.Http, [
    status: 404,
    handlers: {MyApp.FailureHandler, 1},
    reposense: "404 not found",
    percent: 100
]

plug ExFit.Plug.Http, [
   %{
    status: 400,
    handlers: {MyApp.FailureHandler, 1},
    reposense: "404 not found",
    percent: 100
  },
   %{
    status: 404,
    handlers: {MyApp.FailureHandler, 1},
    reposense: "404 not found",
    percent: 100
  }
]
```

## ExFit.HTTPoison

外部へのリクエストをエラーにする場合に使用する
マッチした場合リクエストは中断されレスポンスのみが返る

```
res = ExFit.HTTPoison.request!(:post, path, body, headers)
```


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

