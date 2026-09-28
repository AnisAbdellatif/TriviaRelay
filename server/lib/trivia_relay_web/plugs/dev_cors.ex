defmodule TriviaRelayWeb.Plugs.DevCors do
  @moduledoc """
  Lets a page on another localhost port call the API: `flutter run -d chrome` serves the
  app from its own port, not the relay's. Only when `config :trivia_relay, :dev_cors` is
  set, which is development only; a release serves the app from its own origin.
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with true <- Application.get_env(:trivia_relay, :dev_cors, false),
         [origin] <- get_req_header(conn, "origin"),
         %URI{host: host} when host in ["localhost", "127.0.0.1"] <- URI.parse(origin) do
      conn = cors(conn, origin)
      if conn.method == "OPTIONS", do: conn |> send_resp(204, "") |> halt(), else: conn
    else
      _ -> conn
    end
  end

  defp cors(conn, origin) do
    conn
    |> put_resp_header("access-control-allow-origin", origin)
    |> put_resp_header("access-control-allow-methods", "GET, POST, OPTIONS")
    |> put_resp_header(
      "access-control-allow-headers",
      "content-type, x-player-id, x-player-token, x-device-id, x-player-handle"
    )
    |> put_resp_header("vary", "origin")
  end
end
