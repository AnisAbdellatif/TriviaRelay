defmodule TriviaRelayWeb.Plugs.RateLimit do
  @moduledoc """
  Meters the endpoints that make Sporcle calls for the caller (`TriviaRelay.RateLimit`),
  per address as `TriviaRelayWeb.ClientIp` reads it.

      plug TriviaRelayWeb.Plugs.RateLimit, bucket: :seats, limit: 20, window_ms: 60_000

  The limits sit well above a real evening's play, so hitting one means something is
  wrong. Copied from FazouraParty's plug of the same name.
  """

  @behaviour Plug

  alias TriviaRelay.RateLimit
  alias TriviaRelayWeb.{ApiError, ClientIp}

  @impl true
  def init(opts) do
    %{
      bucket: Keyword.fetch!(opts, :bucket),
      limit: Keyword.fetch!(opts, :limit),
      window_ms: Keyword.fetch!(opts, :window_ms)
    }
  end

  @impl true
  def call(conn, %{bucket: bucket, limit: limit, window_ms: window_ms}) do
    with true <- Application.get_env(:trivia_relay, :rate_limit_enabled, true),
         {:error, :rate_limited} <-
           RateLimit.check(bucket, ClientIp.from_conn(conn), limit, window_ms) do
      conn
      |> Plug.Conn.put_resp_header("retry-after", Integer.to_string(div(window_ms, 1000)))
      |> ApiError.send(
        :too_many_requests,
        "rate_limited",
        "Too many requests. Wait a moment and try again."
      )
      |> Plug.Conn.halt()
    else
      _ -> conn
    end
  end
end
