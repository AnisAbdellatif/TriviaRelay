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
  #
  # A message from a phone arriving in fragments is capped as a single frame is
  # (16 KB, endpoint.ex); Bandit's default is 8 MB. A compressed one may inflate to at most twice its compressed size
  # past the first 16 KB zlib hands back at once (Bandit checks between those chunks),
  # so with frames capped at 16 KB (endpoint.ex) nothing inflates past a few tens of
  # KB. Bandit's default, 25, let a 16 KB frame become 400 KB of JSON to decode. Real
  # intents inflate to well under 16 KB, so they are never refused.
  http: [
    websocket_options: [
      deflate_options: [mem_level: 4],
      max_fragmented_message_size: 16_384,
      max_inflate_ratio: 2
    ]
  ]

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
