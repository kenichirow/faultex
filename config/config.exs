import Config

config :injex,
  disalbe: true,
  failures: [RegisterFailure]

config :injex, RegisterFailure,
  # request matcher(Plug.Connとパターンマッチする)
  host: "example.com",
  path: "/das/auth/:game_id/:game_env/*path",
  method: "POST",
  exact: true,
  header: {"x-nativebase-fault-inject", "das-auth-failed"},

  # response
  percent: 100,
  status: 401,
  # resp_handler: {MyApp.FailureHandler, 1},
  reponse: "{}",
  delay: 1000
