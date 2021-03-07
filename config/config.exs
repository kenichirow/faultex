import Config

config :injex,
  failures: [RegisterFailure]

config :injex, RegisterFailure,
  host: "example.com",
  path: "/das/auth/:game_id/:game_env/*path",
  method: "POST",
  exact: true,
  header: {"x-nativebase-fault-inject", "das-auth-failed"},
  percent: 100,
  status: 401,
  reponse: "{}",
  delay: 1000
