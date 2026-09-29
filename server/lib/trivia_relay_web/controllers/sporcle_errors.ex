defmodule TriviaRelayWeb.SporcleErrors do
  @moduledoc "How a failed call to Sporcle is told to the phone (`protocol/PROTOCOL.md` §3)."

  alias TriviaRelayWeb.ApiError
  alias TriviaRelayWeb.Plugs.RateLimit

  def send(conn, {:error, :invalid_player}),
    do: ApiError.send(conn, :bad_request, "invalid_player", "Sign in to Sporcle first.")

  def send(conn, {:error, "invalid_options"}),
    do: ApiError.send(conn, :bad_request, "invalid_options", "Those game options aren't allowed.")

  def send(conn, {:error, :pack_not_found}),
    do: ApiError.send(conn, :not_found, "pack_not_found", "That pack doesn't exist.")

  def send(conn, {:error, :invalid_token}),
    do: ApiError.send(conn, :unauthorized, "invalid_token", "This seat's token is not valid.")

  def send(conn, {:error, :seat_not_found}),
    do: ApiError.send(conn, :not_found, "seat_not_found", "This seat has ended.")

  # The seat refused, as it refuses an intent: not_host, wrong_phase, not_live.
  def send(conn, {:error, code}) when code in ["not_host", "wrong_phase", "not_live"],
    do: ApiError.send(conn, :conflict, code, TriviaRelayWeb.SeatChannel.message(code))

  def send(conn, {:error, {:http, status, _}}) when status in [401, 403],
    do:
      ApiError.send(
        conn,
        :unauthorized,
        "sporcle_auth",
        "Your Sporcle sign-in has expired. Sign in again."
      )

  def send(conn, {:error, {:refused, body}}),
    do: ApiError.send(conn, :conflict, "game_refused", refusal(body))

  def send(conn, {:error, :rate_limited}), do: RateLimit.refuse(conn, 60)

  # Too many calls to Sporcle already waiting on it (TriviaRelay.Sporcle.Http).
  def send(conn, {:error, :busy}),
    do:
      conn
      |> Plug.Conn.put_resp_header("retry-after", "5")
      |> ApiError.send(
        :service_unavailable,
        "relay_busy",
        "The relay is busy. Try again in a moment."
      )

  # The relay holds as many seats as it can (TriviaRelay.Seats, `:seats_full`); any other
  # way of saying so (the supervisor's own `max_children`) is told the same.
  def send(conn, {:error, reason}) when is_atom(reason) or is_tuple(reason) do
    if full?(reason) do
      conn
      |> Plug.Conn.put_resp_header("retry-after", "60")
      |> ApiError.send(
        :service_unavailable,
        "seats_full",
        "The relay is full right now. Try again in a few minutes."
      )
    else
      unavailable(conn)
    end
  end

  def send(conn, _error), do: unavailable(conn)

  defp unavailable(conn) do
    ApiError.send(
      conn,
      :bad_gateway,
      "sporcle_unavailable",
      "Sporcle didn't answer. Try again in a moment."
    )
  end

  # `:seats_full`, DynamicSupervisor's `max_children`, or any reason that says it is full.
  defp full?(:seats_full), do: true
  defp full?({:seat_failed, reason}), do: full?(reason)
  defp full?(:max_children), do: true

  defp full?(reason) when is_atom(reason),
    do: reason |> Atom.to_string() |> String.contains?("full")

  defp full?(_reason), do: false

  # What Sporcle said when it answered 200 without a player session: a game that doesn't
  # exist, a full game, a guest account. Passed on as it came, since only it knows.
  defp refusal(%{} = body) do
    body["message"] || body["error"] || body["reason"] ||
      "Sporcle wouldn't seat you in that game."
  end

  defp refusal(_), do: "Sporcle wouldn't seat you in that game."
end
