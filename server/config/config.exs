# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :trivia_relay,
  generators: [timestamp_type: :utc_datetime],
  # How long a seat stays in its Sporcle game with no phone attached. Per deployment:
  # SEAT_HOLD_SECONDS in production (runtime.exs).
  seat_hold_ms: 300_000

# Configure the endpoint
config :trivia_relay, TriviaRelayWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: TriviaRelayWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TriviaRelay.PubSub,
  # Each compressed socket keeps its own deflate state; memory level 4 keeps it small
  # (FazouraParty's measurement, see its decisions.md "Connection Memory").
  http: [websocket_options: [deflate_options: [mem_level: 4]]]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Passwords and tokens (Sporcle's and the relay's own seat tokens) never reach a log.
config :phoenix, :filter_parameters, ["password", "token", "player"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
