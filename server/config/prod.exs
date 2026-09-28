import Config

# Force using SSL in production. This also sets the "strict-security-transport" header,
# known as HSTS. Note `:force_ssl` is required to be set at compile-time.
config :trivia_relay, TriviaRelayWeb.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_proto],
    exclude: [
      # kamal-proxy's health check is plain HTTP to the container's own address
      # (deploy/deploy.yml), and a new container only takes traffic once it answers
      # 200 — a redirect would fail every deploy.
      paths: ["/health"],
      hosts: ["localhost", "127.0.0.1"]
    ]
  ]

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
