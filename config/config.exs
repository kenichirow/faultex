import Config

config :injex,
  disable: false,
  failures: [PlugFailure, HttpClientFailure]

config :injex, PlugFailure,
  host: "*",
  path: "/das/auth/:game_id/:game_env/*path",
  method: "POST",
  exact: true,
  header: {"x-fault-inject", "auth-failed"},
  percent: 100,
  status: 401,
  reponse: "{}",
  delay: 1000

config :injex, HttpClientFailure,
  host: "github.com",
  path: "/foo",
  method: "GET",
  header: {"x-fault-inject", "github"},
  percent: 100,
  status: 400,
  reponse: "{}",
  delay: 1000
