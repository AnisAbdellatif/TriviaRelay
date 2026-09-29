defmodule TriviaRelayWeb.LoginController do
  @moduledoc """
  `POST /api/login` (`protocol/PROTOCOL.md` §3.1): a Sporcle email and password for
  Party credentials, for the web build, which may not call sporcle.com itself. The
  password goes to Sporcle and nowhere else: it is not stored, and `password` is
  filtered out of every log (`config :phoenix, :filter_parameters`).

  Only a page of the relay's own origin may call it (`TriviaRelayWeb.Plugs.SameOrigin`,
  in the router), and failed logins are metered per email and across the relay
  (`TriviaRelayWeb.Meters`), so the relay can't be used to try passwords.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Sporcle.{Cred, Login}
  alias TriviaRelayWeb.{ApiError, Meters, SporcleErrors}
  alias TriviaRelayWeb.Plugs.RateLimit

  def create(conn, %{"email" => email, "password" => password} = params)
      when is_binary(email) and byte_size(email) in 3..254 and is_binary(password) and
             byte_size(password) in 1..512 do
    # The device id the app made for itself: the token is bound to it, and the app sends
    # the same one as X-UDID afterwards. Its own default is used if the app omits it.
    with {:ok, args} <- device(params["device_id"]),
         :ok <- Meters.login_allowed(email) do
      result = apply(Login, :login, [email, password | args])
      Meters.login_result(email, result)
      respond(conn, result)
    else
      :invalid_device ->
        ApiError.send(conn, :bad_request, "invalid_request", "That device id isn't valid.")

      {:error, :rate_limited} ->
        RateLimit.refuse(conn, 60)
    end
  end

  def create(conn, _params),
    do: ApiError.send(conn, :bad_request, "invalid_request", "Send an email and a password.")

  defp device(nil), do: {:ok, []}
  defp device(id), do: if(Cred.device_id?(id), do: {:ok, [id]}, else: :invalid_device)

  defp respond(conn, {:ok, player}), do: json(conn, player)

  defp respond(conn, {:error, :bad_credentials}) do
    ApiError.send(
      conn,
      :unauthorized,
      "login_failed",
      "That email and password don't match a Sporcle account."
    )
  end

  defp respond(conn, {:error, :busy}), do: SporcleErrors.send(conn, {:error, :busy})

  defp respond(conn, {:error, _}) do
    ApiError.send(
      conn,
      :bad_gateway,
      "sporcle_unavailable",
      "Sporcle didn't answer. Try again in a moment."
    )
  end
end
