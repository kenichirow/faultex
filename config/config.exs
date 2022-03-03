import Config

config :injex,
  disable: false,
  failures: [PlugFailure, HttpClientFailure]

config :injex, PlugFailure,
  host: "*",
  path: "/auth/:id/*path",
  method: "POST",
  exact: true,
  headers: {"x-fault-inject", "auth-failed"},
  percentage: 100,
  resp_headers: [],
  resp_status: 401,
  resp_body: "{}",
  resp_delay: 1000

config :injex, HttpClientFailure,
  host: "github.com",
  path: "/foo",
  method: "GET",
  headers: {"x-fault-inject", "github"},
  percentage: 100,
  resp_headers: [],
  resp_status: 400,
  resp_body: "{}",
  resp_delay: 1000
