defmodule TriviaRelayWeb.Plugs.SameOrigin do
  @moduledoc """
  Lets through only a request a page of the relay's own origin made: its `Origin` header
  must be the endpoint's URL (`PHX_HOST`). For `/api/login`, which only the web build the
  relay serves calls (the Android app logs in on the phone), so that no other page, and
  no script that isn't a browser pretending well, can use the relay to try passwords.

  A browser always sends `Origin` on a POST. In development (`:dev_cors`) a page on
  another localhost port is let through too, as `TriviaRelayWeb.Plugs.DevCors` lets it
  call at all.

  Refused with `403 forbidden_origin`.
  """

  @behaviour Plug

  alias TriviaRelayWeb.ApiError

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Plug.Conn.get_req_header(conn, "origin") do
      [origin] -> if allowed?(origin), do: conn, else: refuse(conn)
      _ -> refuse(conn)
    end
  end

  @doc "Whether `origin` is the relay's own, or a development page's."
  def allowed?(origin) do
    origin = URI.parse(origin)
    own = URI.parse(TriviaRelayWeb.Endpoint.url())

    same?(origin, own) or
      (Application.get_env(:trivia_relay, :dev_cors, false) and
         origin.host in ["localhost", "127.0.0.1"])
  end

  defp same?(%URI{scheme: scheme, host: host, port: port}, %URI{} = own)
       when is_binary(scheme) and is_binary(host) do
    String.downcase(scheme) == own.scheme and String.downcase(host) == String.downcase(own.host) and
      port == own.port
  end

  defp same?(_origin, _own), do: false

  defp refuse(conn) do
    conn
    |> ApiError.send(:forbidden, "forbidden_origin", "Log in from the relay's own web app.")
    |> Plug.Conn.halt()
  end
end
