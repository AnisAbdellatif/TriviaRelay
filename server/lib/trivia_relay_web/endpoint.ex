defmodule TriviaRelayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :trivia_relay

  # Phones reach their seats here (protocol/PROTOCOL.md §2). Snapshots are compressed
  # (permessage-deflate) for every client that offers it; each compressed socket keeps
  # its own deflate state, kept small with mem_level 4 (config.exs), as FazouraParty
  # measured.
  #
  # Intents are small (an answer is at most 200 characters), and anybody may send a
  # socket anything before joining a seat, so a message is capped small however it
  # arrives: one frame here, fragments together in config.exs
  # (`max_fragmented_message_size`, which Phoenix doesn't pass on; Bandit's default is
  # 8 MB). A compressed one may inflate only so far (`max_inflate_ratio`, config.exs).
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
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    length: 16_384,
    json_decoder: Phoenix.json_library()

  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_trivia_relay_admin",
    signing_salt: "admin session",
    http_only: true,
    same_site: "Strict"

  # The web app at "/" (WEB_DIR), before the router, which only knows /api and /health.
  plug TriviaRelayWeb.Plugs.WebApp
  plug TriviaRelayWeb.Router
end
