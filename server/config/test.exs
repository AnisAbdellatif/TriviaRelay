import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :trivia_relay, TriviaRelayWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Hvt5XVvdXglfCNiHA06aQCXD02TsEvEn1vxcoTIlqKMi4lRG0ZklVH5An2vJRsO/",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Snapshots go out at once, seats close without waiting, and nothing reaches Sporcle:
# every Sporcle call goes to a Req.Test stub a test puts in place.
config :trivia_relay,
  broadcast_interval_ms: 0,
  drain_ms: 0,
  seat_hold_ms: 60_000,
  rate_limit_enabled: false,
  sporcle_http: [plug: {Req.Test, TriviaRelay.Sporcle}],
  sporcle_api_key: "test-api-key",
  upstream: TriviaRelay.FakeUpstream

config :ex_unit, assert_receive_timeout: 1000
