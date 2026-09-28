defmodule TriviaRelayWeb.LoginController do
  @moduledoc """
  `POST /api/login` (`protocol/PROTOCOL.md` §3.1): a Sporcle email and password for
  Party credentials, for the web build, which may not call sporcle.com itself. The
  password goes to Sporcle and nowhere else: it is not stored, and `password` is
  filtered out of every log (`config :phoenix, :filter_parameters`).
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Sporcle.Login
  alias TriviaRelayWeb.ApiError

  def create(conn, %{"email" => email, "password" => password} = params)
      when is_binary(email) and is_binary(password) do
    # The device id the app made for itself: the token is bound to it, and the app sends
    # the same one as X-UDID afterwards. Its own default is used if the app omits it.
    args = if is_binary(params["device_id"]), do: [params["device_id"]], else: []

    case apply(Login, :login, [email, password | args]) do
      {:ok, player} ->
        json(conn, player)

      {:error, :bad_credentials} ->
        ApiError.send(
          conn,
          :unauthorized,
          "login_failed",
          "That email and password don't match a Sporcle account."
        )

      {:error, _} ->
        ApiError.send(
          conn,
          :bad_gateway,
          "sporcle_unavailable",
          "Sporcle didn't answer. Try again in a moment."
        )
    end
  end

  def create(conn, _params),
    do: ApiError.send(conn, :bad_request, "invalid_request", "Send an email and a password.")
end
