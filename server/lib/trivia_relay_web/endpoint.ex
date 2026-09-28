defmodule TriviaRelayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :trivia_relay

  # Phones reach their seats here (protocol/PROTOCOL.md §2). Snapshots are compressed
  # (permessage-deflate) for every client that offers it; each compressed socket keeps
  # its own deflate state, kept small with mem_level 4 (config.exs), as FazouraParty
  # measured. Intents are small, so frames are capped small.
  socket "/socket", TriviaRelayWeb.UserSocket,
    websocket: [
      connect_info: [:peer_data, :x_headers],
      max_frame_size: 16_384,
      compress: true,
      serializer: [
        {Phoenix.Socket.V1.JSONSerializer, "~> 1.0.0"},
        {TriviaRelayWeb.Serializer, "~> 2.0.0"}
      ]
    ],
    longpoll: false

  plug Plug.Static,
    at: "/",
    from: :trivia_relay,
    gzip: not code_reloading?,
    only: TriviaRelayWeb.static_paths(),
    raise_on_missing_only: code_reloading?

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug TriviaRelayWeb.Plugs.DevCors
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    length: 16_384,
    json_decoder: Phoenix.json_library()

  plug Plug.Head
  # The web app at "/" (WEB_DIR), before the router, which only knows /api and /health.
  plug TriviaRelayWeb.Plugs.WebApp
  plug TriviaRelayWeb.Router
end
