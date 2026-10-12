defmodule TriviaRelayWeb.PopperController do
  @moduledoc """
  `POST /api/poppers/claim` (`protocol/PROTOCOL.md` §3.5, since 1.2): claims the Party
  Poppers Sporcle has given the player back (one every 4 hours, up to 5), with the
  credentials from the `x-player-*` headers, and says how many they have.

  A game with pictures costs a player who isn't its host one Popper to join. Buying
  them is Sporcle's own app's business, and not here.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Sporcle.{Api, Cred}
  alias TriviaRelayWeb.{PackController, SporcleErrors}

  def claim(conn, _params) do
    with {:ok, cred} <- Cred.new(PackController.player(conn)),
         {:ok, body} <- Api.claim_poppers(cred) do
      json(conn, %{
        poppers: count(body["popper_count"]),
        last_claim: time(body["popper_last_claim"])
      })
    else
      error -> SporcleErrors.send_action(conn, error)
    end
  end

  defp count(n) when is_integer(n) and n >= 0, do: n
  defp count(_), do: nil

  # Sporcle's is Unix seconds (the official app divides Date.now() by 1000 to compare);
  # the protocol's times are milliseconds.
  defp time(seconds) when is_integer(seconds) and seconds > 0, do: seconds * 1000
  defp time(_), do: nil
end
