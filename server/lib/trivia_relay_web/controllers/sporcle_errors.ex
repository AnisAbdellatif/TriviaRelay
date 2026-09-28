defmodule TriviaRelayWeb.SporcleErrors do
  @moduledoc "How a failed call to Sporcle is told to the phone (`protocol/PROTOCOL.md` §3)."

  alias TriviaRelayWeb.ApiError

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

  def send(conn, _error),
    do:
      ApiError.send(
        conn,
        :bad_gateway,
        "sporcle_unavailable",
        "Sporcle didn't answer. Try again in a moment."
      )

  # What Sporcle said when it answered 200 without a player session: a game that doesn't
  # exist, a full game, a guest account. Passed on as it came, since only it knows.
  defp refusal(%{} = body) do
    body["message"] || body["error"] || body["reason"] ||
      "Sporcle wouldn't seat you in that game."
  end

  defp refusal(_), do: "Sporcle wouldn't seat you in that game."
end
