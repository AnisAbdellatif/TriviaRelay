defmodule TriviaRelayWeb.BypassController do
  @moduledoc """
  A device's side of bypass codes: redeeming one for a bearer (`/api/bypass/redeem`)
  and asking whether a bearer is still good (`/api/bypass/check`, the bearer in the
  `x-bypass-token` header). Codes are managed at `/admin`.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Bypass
  alias TriviaRelayWeb.ApiError

  def redeem(conn, %{"code" => code, "device_id" => device_id})
      when is_binary(code) and is_binary(device_id) do
    case Bypass.redeem(code, device_id) do
      {:ok, bearer} ->
        json(conn, %{bearer: bearer})

      {:error, :not_found} ->
        ApiError.send(conn, :not_found, "not_found", "That code doesn't exist.")

      {:error, :already_used} ->
        ApiError.send(conn, :conflict, "already_used", "That code was already used.")

      {:error, :bypass_disabled} ->
        ApiError.send(conn, :service_unavailable, "bypass_disabled", "Bypass is off.")
    end
  end

  def redeem(conn, _params),
    do: ApiError.send(conn, :bad_request, "invalid_request", "Send a code and a device id.")

  def check(conn, _params) do
    with [bearer] <- get_req_header(conn, "x-bypass-token"),
         {:ok, _device_id} <- Bypass.verify_bearer(bearer) do
      send_resp(conn, :no_content, "")
    else
      _ -> ApiError.send(conn, :forbidden, "bypass_revoked", "Bypass access was revoked.")
    end
  end
end
