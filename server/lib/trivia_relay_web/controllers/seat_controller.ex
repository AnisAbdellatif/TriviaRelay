defmodule TriviaRelayWeb.SeatController do
  @moduledoc """
  Taking a seat (`protocol/PROTOCOL.md` §3.3): `POST /api/seats` joins a Sporcle game by
  code, `POST /api/seats/host` creates one and seats its host. Both answer `201` with
  `{seat_id, seat_token, game_code}`; the phone then joins `seat:<seat_id>`.
  `POST /api/seats/pack` is the host changing the pack in the lobby.

  The player's credentials (`player`) are used for the one Sporcle call and not kept.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Seats
  alias TriviaRelay.Sporcle.Cred
  alias TriviaRelayWeb.{ApiError, SporcleErrors}

  def join(conn, %{"code" => code} = params) when is_binary(code) do
    code = String.trim(code)

    if Regex.match?(~r/^\d{4,8}$/, code) do
      with {:ok, cred} <- Cred.new(params["player"]),
           {:ok, seat} <- Seats.join(cred, code) do
        created(conn, seat)
      else
        error -> SporcleErrors.send(conn, error)
      end
    else
      ApiError.send(conn, :bad_request, "invalid_code", "A game code is 4 to 8 digits.")
    end
  end

  def join(conn, _params),
    do: ApiError.send(conn, :bad_request, "invalid_code", "Send the game code.")

  def host(conn, %{"pack_id" => pack_id} = params) when is_integer(pack_id) do
    with {:ok, cred} <- Cred.new(params["player"]),
         {:ok, seat} <- Seats.host(cred, pack_id, params["options"]) do
      created(conn, seat)
    else
      error -> SporcleErrors.send(conn, error)
    end
  end

  def host(conn, _params),
    do: ApiError.send(conn, :bad_request, "pack_not_found", "Choose a pack.")

  def change_pack(conn, %{"pack_id" => pack_id, "seat_token" => token} = params)
      when is_integer(pack_id) and is_binary(token) do
    with {:ok, cred} <- Cred.new(params["player"]),
         :ok <- Seats.change_pack(cred, token, pack_id) do
      send_resp(conn, :no_content, "")
    else
      error -> SporcleErrors.send(conn, error)
    end
  end

  def change_pack(conn, _params),
    do: ApiError.send(conn, :bad_request, "pack_not_found", "Choose a pack.")

  defp created(conn, seat) do
    conn
    |> put_status(:created)
    |> json(%{seat_id: seat.id, seat_token: seat.token, game_code: seat.game_code})
  end
end
