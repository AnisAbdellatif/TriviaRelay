import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/trivia_relay start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
# In development, `.env` (next to mix.exs, git-ignored) supplies what the environment
# doesn't: copy `.env.example` to start one. A variable already set wins.
if config_env() == :dev do
  env_file = Path.expand("../.env", __DIR__)

  if File.exists?(env_file) do
    for line <- File.read!(env_file) |> String.split("\n"),
        line = String.trim(line),
        line != "" and not String.starts_with?(line, "#"),
        [name, value] = String.split(line, "=", parts: 2),
        name = String.trim(name),
        System.get_env(name) == nil do
      System.put_env(name, value |> String.trim() |> String.trim("\""))
    end
  end
end

# The Sporcle Party app's API key, sent with every call to Sporcle. Not in the repository:
# `.env.example` says what it is and where to find it. Tests use their own (test.exs).
if config_env() != :test do
  config :trivia_relay,
         :sporcle_api_key,
         System.get_env("SPORCLE_API_KEY") ||
           raise("""
           environment variable SPORCLE_API_KEY is missing.
           It is the Sporcle Party app's API key; server/.env.example says where to find
           it. In development, put it in server/.env.
           """)
end

if System.get_env("PHX_SERVER") do
  config :trivia_relay, TriviaRelayWeb.Endpoint, server: true
end

config :trivia_relay, TriviaRelayWeb.Endpoint,
  # 4100 by default, so the relay and FazouraParty's server (4000) can run side by side.
  http: [port: String.to_integer(System.get_env("PORT", "4100"))]

# How long a seat stays in its Sporcle game after its phone went away, in seconds: the
# player keeps their place, and Sporcle never sees them leave, for this long.
if hold = System.get_env("SEAT_HOLD_SECONDS") do
  config :trivia_relay, :seat_hold_ms, String.to_integer(hold) * 1000
end

# The built web app (`flutter build web` in app/), served at "/".
if web_dir = System.get_env("WEB_DIR") do
  config :trivia_relay, :web_dir, web_dir
end

# How many X-Forwarded-For entries are our own proxies' (TriviaRelayWeb.ClientIp). Only
# believable while nothing but those proxies can reach the relay.
if hops = System.get_env("TRUST_PROXY") do
  config :trivia_relay, :proxy_hops, String.to_integer(hops)
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :trivia_relay, TriviaRelayWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://bandit.hexdocs.pm/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :trivia_relay, TriviaRelayWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://plug.hexdocs.pm/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :trivia_relay, TriviaRelayWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
