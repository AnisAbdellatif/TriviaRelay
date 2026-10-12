defmodule TriviaRelayWeb.PackActionController do
  @moduledoc """
  What a player does to a pack in Sporcle's catalog (`protocol/PROTOCOL.md` §3.2, since
  1.2), with the credentials from the `x-player-*` headers:

    * `POST /api/packs/:id/bookmark` `{bookmarked}`: bookmark it, or stop.
    * `POST /api/packs/:id/subscribe` `{subscribed}`: be told, in Sporcle Party's own
      app, when somebody hosts it; or stop.
    * `POST /api/packs/:id/report` `{reason, details}`: report it to Sporcle.

  Nothing of any of it is kept. Reports are limited per account besides per address
  (`TriviaRelayWeb.Meters`): each one lands in Sporcle's queue from the relay's address.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Sporcle.{Api, Cred}
  alias TriviaRelayWeb.{ApiError, Meters, PackController, SporcleErrors}

  # The official app's report box takes at most 200 characters, and needs some.
  @max_details 200

  def bookmark(conn, %{"id" => id, "bookmarked" => on}) when is_boolean(on) do
    toggle(conn, id, fn cred, pack_id -> Api.bookmark_pack(cred, pack_id, on) end, %{
      bookmarked: on
    })
  end

  def bookmark(conn, _params), do: invalid(conn, "Say whether to bookmark the pack.")

  def subscribe(conn, %{"id" => id, "subscribed" => on}) when is_boolean(on) do
    toggle(conn, id, fn cred, pack_id -> Api.subscribe_pack(cred, pack_id, on) end, %{
      subscribed: on
    })
  end

  def subscribe(conn, _params), do: invalid(conn, "Say whether to subscribe to the pack.")

  def report(conn, %{"id" => id, "reason" => reason, "details" => details})
      when is_binary(reason) and is_binary(details) do
    with {:ok, pack_id} <- PackController.pack_id(id),
         {:ok, cred} <- Cred.new(PackController.player(conn)),
         true <- reason in Api.report_reasons() || :invalid_reason,
         {:ok, details} <- details(details),
         :ok <- Meters.account_allowed(:report, cred),
         {:ok, _} <-
           Meters.account_result(
             :report,
             cred,
             Api.report_pack(cred, pack_id, reason, details)
           ) do
      send_resp(conn, :no_content, "")
    else
      :invalid_reason -> invalid(conn, "Pick one of the reasons offered.")
      :invalid_details -> invalid(conn, "Say what is wrong, in up to #{@max_details} characters.")
      error -> SporcleErrors.send_action(conn, error)
    end
  end

  def report(conn, _params), do: invalid(conn, "Pick a reason and say what is wrong.")

  defp toggle(conn, id, call, answer) do
    with {:ok, pack_id} <- PackController.pack_id(id),
         {:ok, cred} <- Cred.new(PackController.player(conn)),
         {:ok, _} <- call.(cred, pack_id) do
      json(conn, answer)
    else
      error -> SporcleErrors.send_action(conn, error)
    end
  end

  # What the player wrote, as text Sporcle's staff will read: valid, trimmed, bounded,
  # without the characters that only hide or move text.
  defp details(text) do
    text =
      if String.valid?(text),
        do: text |> String.replace(~r/[\p{Cc}\p{Cf}]/u, " ") |> String.trim(),
        else: ""

    if text != "" and String.length(text) <= @max_details,
      do: {:ok, text},
      else: :invalid_details
  end

  defp invalid(conn, message), do: ApiError.send(conn, :bad_request, "invalid_request", message)
end
