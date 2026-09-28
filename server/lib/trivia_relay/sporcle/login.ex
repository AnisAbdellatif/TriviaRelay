defmodule TriviaRelay.Sporcle.Login do
  @moduledoc """
  A Sporcle email and password, exchanged for Party credentials, the way the official
  app does it (confirmed by capturing it — `sporcle_scraper/RE/find_connect.py`):

    1. `GET www.sporcle.com/login/?party_udid=<udid>` → primes the session for the app
    2. `POST www.sporcle.com/auth/ajax/login.php {email, passwd, remember}`
       → `{success, logged_in, user_id, handle, token}`, where `user_id` is the
       sporcle_id (X-SPORCLE-PLAYER) and `token` is X-SPORCLE-TOKEN.

  Without step 1 the login returns only `{success, logged_in}` and no token. The token
  is bound to the udid, so the same one must be sent later as X-UDID.

  Only the web build logs in through here, because a browser may not make these calls
  itself; the Android app runs the same flow on the phone. The password is used for the
  login POST and forgotten: nothing here stores or logs it, and neither does the
  controller in front of it.
  """

  require Logger

  alias TriviaRelay.Sporcle.{Http, Identity}

  @site "https://www.sporcle.com"
  @doc "Returns `{:ok, %{player_id, token, handle}}` or `{:error, reason}`."
  # The device's udid, sent later as X-UDID: the party token is bound to it, so login
  # and every Party call must use the same one.
  @default_udid "956aa24a2296d663"

  def login(email, password, device_id \\ @default_udid)
      when is_binary(email) and is_binary(password) do
    with {:ok, cookies} <- step(:prime, prime(device_id)) do
      step(:login, party_login(email, password, cookies))
    end
  end

  # Loading the party login page with the udid, as the Party app (its user agent gates
  # the party flow), puts the session in party context so the login POST then returns the
  # token. Without it login.php returns only {success, logged_in} (confirmed by capturing
  # the official app; see RE/find_connect.py).
  defp prime(device_id) do
    case Http.request(
           method: :get,
           url: @site <> "/login/?party_udid=" <> URI.encode(device_id),
           headers: %{"user-agent" => Identity.user_agent_api()}
         ) do
      {:ok, %{status: 200} = resp} -> {:ok, cookies(resp)}
      {:ok, %{status: status}} -> {:error, {:sporcle, status}}
      {:error, e} -> {:error, e}
    end
  end

  defp party_login(email, password, cookies) do
    case Http.request(
           method: :post,
           url: @site <> "/auth/ajax/login.php",
           form: [email: email, passwd: password, remember: 1],
           headers: %{"user-agent" => Identity.user_agent_api(), "cookie" => cookies}
         ) do
      {:ok, %{status: 200, body: body}} -> from_login(decode(body), email)
      {:ok, %{status: status}} -> {:error, {:sporcle, status}}
      {:error, e} -> {:error, e}
    end
  end

  defp from_login(
         %{"success" => true, "logged_in" => true, "user_id" => id, "token" => token} = b,
         email
       )
       when is_binary(id) and is_binary(token) do
    {:ok, %{player_id: id, token: token, handle: b["handle"] || email}}
  end

  defp from_login(%{"success" => true, "logged_in" => true}, _email),
    do: {:error, :no_party_token}

  defp from_login(_body, _email), do: {:error, :bad_credentials}

  # Which step failed and why, never with anything the player sent.
  defp step(_name, {:ok, _} = ok), do: ok
  defp step(_name, {:error, :bad_credentials} = error), do: error

  defp step(name, {:error, reason} = error) do
    Logger.warning("Sporcle login failed at #{name}: #{inspect(reason)}")
    error
  end

  defp cookies(resp) do
    resp
    |> Req.Response.get_header("set-cookie")
    |> Enum.map_join("; ", &(&1 |> String.split(";") |> hd()))
  end

  defp decode(body) when is_map(body), do: body

  defp decode(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, map} when is_map(map) -> map
      _ -> %{}
    end
  end

  defp decode(_), do: %{}
end
