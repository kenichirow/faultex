import Config

config :injex,
  disable: false,
  failures: [RegisterFailure, GithubFail]

config :injex, RegisterFailure,
  host: "*",
  path: "/das/auth/:game_id/:game_env/*path",
  method: "POST",
  exact: true,
  header: {"x-nativebase-fault-inject", "das-auth-failed"},
  percent: 100,
  status: 401,
  reponse: "{}",
  delay: 1000

config :injex, GithubFail,
  host: "github.com",
  path: "/das/foo",
  method: "GET",
  header: {"x-nativebase-fault-inject", "github"},
  percent: 100,
  status: 400,
  reponse: "{}",
  delay: 1000
