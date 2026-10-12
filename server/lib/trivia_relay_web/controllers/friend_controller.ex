defmodule TriviaRelayWeb.FriendController do
  @moduledoc """
  The player's Sporcle friends, and inviting them to the game the player is in
  (`protocol/PROTOCOL.md` §3.6, since 1.2). Credentials come from the `x-player-*`
  headers.

    * `GET /api/friends?page=…`: a page of friends. Kept 30 s for the same credentials
      (`TriviaRelay.Cache`), never anybody else's.
    * `POST /api/invites` `{seat_token, code, pack_id, friend_id}`: invites one friend,
      or all of them when `friend_id` is null. Only from a seat this player holds, and
      limited per account besides per address (`TriviaRelayWeb.Meters`): each invite
      is a notification on somebody's phone, sent from the relay's address.

  The invitation names the game's pack as Sporcle has it, never as the phone says it.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.{Cache, Seats}
  alias TriviaRelay.Sporcle.{Api, Cred}
  alias TriviaRelayWeb.{ApiError, Meters, PackController, SporcleErrors}

  @ttl_ms 30_000
  # A pack's name and picture change rarely and are nobody's in particular.
  @pack_ttl_ms 10 * 60_000
  @max_name 40

  def index(conn, params) do
    page = page(params["page"])

    with {:ok, cred} <- Cred.new(PackController.player(conn)),
         {:ok, friends} <-
           Cache.fetch({:friends, Cred.key(cred), page}, @ttl_ms, fn -> fetch(cred, page) end) do
      json(conn, %{friends: friends, next_page: if(friends != [], do: page + 1)})
    else
      error -> SporcleErrors.send(conn, error)
    end
  end

  def invite(conn, %{"seat_token" => token, "code" => code, "pack_id" => pack_id} = params)
      when is_binary(token) and is_binary(code) and is_integer(pack_id) do
    with {:ok, friend} <- invitee(params["friend_id"]),
         true <- Regex.match?(~r/\A\d{4,8}\z/, code) || :invalid_code,
         {:ok, cred} <- Cred.new(PackController.player(conn)),
         :ok <- Seats.owned(cred, token),
         kind = if(friend == :all, do: :invite_all, else: :invite),
         :ok <- Meters.account_allowed(kind, cred),
         {:ok, pack} <- card(cred, pack_id),
         game = %{gameCode: code, gamePack: pack},
         {:ok, _} <- Meters.account_result(kind, cred, Api.invite(cred, friend, game)) do
      send_resp(conn, :no_content, "")
    else
      :invalid_code ->
        ApiError.send(conn, :bad_request, "invalid_code", "A game code is 4 to 8 digits.")

      :invalid_friend ->
        ApiError.send(conn, :bad_request, "invalid_request", "That isn't one of your friends.")

      error ->
        SporcleErrors.send_action(conn, error)
    end
  end

  def invite(conn, _params),
    do: ApiError.send(conn, :bad_request, "invalid_request", "Say which game to invite to.")

  defp fetch(cred, page) do
    with {:ok, friends} <- Api.friends(cred, page), do: {:ok, friends(friends)}
  end

  # Sporcle's friends come as a map by the id an invitation takes (decompiled only); a
  # list of player maps is read too. Only accepted friends, not requests either way.
  defp friends(%{} = by_id), do: by_id |> Enum.flat_map(fn {id, p} -> friend(id, p) end) |> sort()

  defp friends(list) when is_list(list),
    do: for(%{} = p <- list, f <- friend(p["playerId"], p), do: f) |> sort()

  defp friends(_), do: []

  defp friend(id, %{} = p) when is_binary(id) do
    status = p["friendStatus"]

    if friend_id?(id) and (not is_map(status) or status["is_friend"] == true) do
      handle = text(p["sporcleHandle"])
      [%{id: id, name: text(p["teamName"]) || handle || "Friend", handle: handle}]
    else
      []
    end
  end

  defp friend(_id, _p), do: []

  defp sort(friends), do: Enum.sort_by(friends, &String.downcase(&1.name))

  defp invitee(nil), do: {:ok, :all}

  defp invitee(id) when is_binary(id),
    do: if(friend_id?(id), do: {:ok, id}, else: :invalid_friend)

  defp invitee(_), do: :invalid_friend

  # Sporcle's ids: `xAc71a08as`, or `sporcle_id//xAc71a08as` as the game server has them.
  defp friend_id?(id), do: String.match?(id, ~r/\A[A-Za-z0-9_.:\/-]{1,80}\z/)

  defp text(name) when is_binary(name) do
    case Cred.name(name) do
      nil -> nil
      name -> String.slice(name, 0, @max_name)
    end
  end

  defp text(_), do: nil

  # What an invitation shows of the pack: its id, name and picture, as Sporcle has them.
  defp card(cred, pack_id) do
    Cache.fetch({:pack_card, pack_id}, @pack_ttl_ms, fn ->
      case Api.get_pack(cred, pack_id) do
        {:ok, %{"id" => id} = pack} ->
          {:ok, %{id: id, name: pack["name"] || "", img_src: pack["img_src"] || ""}}

        {:ok, _} ->
          {:error, :pack_not_found}

        error ->
          error
      end
    end)
  end

  defp page(page) when is_binary(page) do
    case Integer.parse(page) do
      {n, ""} when n >= 0 and n < 100 -> n
      _ -> 0
    end
  end

  defp page(_), do: 0
end
