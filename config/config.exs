import Config

config :injex,
  disable: false,
  failures: [PlugFailure, HttpClientFailure]

config :injex, PlugFailure,
  host: "*",
  path: "/das/auth/:game_id/:game_env/*path",
  method: "POST",
  exact: true,
  headers: {"x-fault-inject", "auth-failed"},
  percent: 100,
  resp_headers: [],
  resp_status: 401,
  resp_body: "{}",
  resp_delay: 1000

config :injex, HttpClientFailure,
  host: "github.com",
  path: "/foo",
  method: "GET",
  headers: {"x-fault-inject", "github"},
  percent: 100,
  resp_headers: [],
  resp_status: 400,
  resp_body: "{}",
  resp_delay: 1000
