defmodule TriviaRelayWeb.Meters do
  @moduledoc """
  The meters that count what a request led to, not only that it came
  (`TriviaRelayWeb.Plugs.RateLimit` counts the requests, per address). Each is asked
  before the Sporcle call and counted after it, from the outcome:

    * **Logins that fail**, per email and across the relay. The relay must not become a
      way to try passwords against Sporcle: an email with 5 failures in 15 minutes is
      refused for the rest of them, and 30 failures a minute across the relay stop
      every login until the minute ends. The email is only ever kept as an HMAC (keyed
      by the endpoint's secret), never as written, and never logged.
    * **Seats**, per Sporcle account: games created and joins. Counted only once
      Sporcle has answered for the account (a seat, or a refusal), so nobody can spend
      somebody else's allowance by sending their player id with a made-up token.
    * **Refused joins** — codes Sporcle has no place in, the way somebody guessing codes
      spends their tries — per account and per address (an IPv6 caller's /64 and /48),
      more tightly than joins that work.
    * **What reaches other people**, per Sporcle account: packs reported (10 an hour),
      friends invited one by one (30 per 15 minutes) and all at once (3 per 15
      minutes). Each lands in somebody's notifications or Sporcle's report queue, from
      the relay's one address, so a script mustn't be able to repeat it.

  Each refusal is `{:error, :rate_limited}`, told as `429 rate_limited`. Off when
  `:rate_limit_enabled` is (tests turn it on where they test it).
  """

  alias TriviaRelay.RateLimit
  alias TriviaRelay.Sporcle.Cred
  alias TriviaRelayWeb.ClientIp
  alias TriviaRelayWeb.Plugs.RateLimit, as: Plug

  @hour 60 * 60_000
  @quarter_hour 15 * 60_000
  @minute 60_000

  @reports_per_account 10
  @invites_per_account 30
  @invite_alls_per_account 3

  @login_failures_per_email 5
  @login_failures_per_minute 30

  @hosts_per_account 10
  @joins_per_account 20
  @refused_joins 10

  @doc "Whether a login for `email` may be tried now."
  @spec login_allowed(String.t()) :: :ok | {:error, :rate_limited}
  def login_allowed(email) do
    if Plug.enabled?() and
         (RateLimit.exceeded?(:login_failures, "all", @login_failures_per_minute, @minute) or
            RateLimit.exceeded?(
              :login_email_failures,
              email_key(email),
              @login_failures_per_email,
              @quarter_hour
            )),
       do: {:error, :rate_limited},
       else: :ok
  end

  @doc "Counts a login's outcome: only a wrong email or password counts."
  def login_result(email, {:error, :bad_credentials}) do
    RateLimit.check(:login_failures, "all", @login_failures_per_minute, @minute)

    RateLimit.check(
      :login_email_failures,
      email_key(email),
      @login_failures_per_email,
      @quarter_hour
    )

    :ok
  end

  def login_result(_email, _result), do: :ok

  @doc "Whether `cred` may take a seat by `kind` (`:host` or `:join`) now, from `ip`."
  @spec seat_allowed(:host | :join, Cred.t(), String.t() | nil) :: :ok | {:error, :rate_limited}
  def seat_allowed(kind, %Cred{} = cred, ip) do
    over? =
      RateLimit.exceeded?(bucket(kind), cred.player_id, limit(kind), @quarter_hour) or
        (kind == :join and
           RateLimit.any_exceeded?(:refused_joins, refused_keys(cred, ip), @quarter_hour))

    if Plug.enabled?() and over?, do: {:error, :rate_limited}, else: :ok
  end

  @doc "Counts what taking a seat by `kind` came to. Returns `result`."
  def seat_result(kind, %Cred{} = cred, ip, result) do
    if answered?(result),
      do: RateLimit.check(bucket(kind), cred.player_id, limit(kind), @quarter_hour)

    if kind == :join and refused?(result),
      do: RateLimit.check_all(:refused_joins, refused_keys(cred, ip), @quarter_hour)

    result
  end

  @doc """
  Whether `cred` may ask Sporcle to do `kind` now, for the things a player asks Sporcle
  to do that reach other people or Sporcle's staff: `:report` (a pack reported),
  `:invite` (one friend invited) and `:invite_all` (every friend at once). Counted, as
  seats are, only once Sporcle has answered for the account (`account_result/3`).
  """
  @spec account_allowed(:report | :invite | :invite_all, Cred.t()) ::
          :ok | {:error, :rate_limited}
  def account_allowed(kind, %Cred{} = cred) do
    {limit, window} = allowance(kind)

    if Plug.enabled?() and RateLimit.exceeded?(kind, cred.player_id, limit, window),
      do: {:error, :rate_limited},
      else: :ok
  end

  @doc "Counts what `kind` came to for `cred`. Returns `result`."
  def account_result(kind, %Cred{} = cred, result) do
    {limit, window} = allowance(kind)
    if answered?(result), do: RateLimit.check(kind, cred.player_id, limit, window)
    result
  end

  defp allowance(:report), do: {@reports_per_account, @hour}
  defp allowance(:invite), do: {@invites_per_account, @quarter_hour}
  defp allowance(:invite_all), do: {@invite_alls_per_account, @quarter_hour}

  defp bucket(:host), do: :account_hosts
  defp bucket(:join), do: :account_joins

  defp limit(:host), do: @hosts_per_account
  defp limit(:join), do: @joins_per_account

  defp refused_keys(cred, ip),
    do: [{"account:" <> cred.player_id, @refused_joins} | ClientIp.limits(ip, @refused_joins)]

  # Sporcle answered for this account: it seated it, or knew it and refused the code.
  defp answered?({:ok, _}), do: true
  defp answered?(result), do: refused?(result)

  # A code Sporcle has no place in: it answers 200 with no session, or an error that
  # isn't about the sign-in. A game that exists but won't take this player (no Party
  # Popper for its pictures, full, blocked) is no sign of guessing.
  defp refused?({:error, {:refused, %{"denied" => %{"code" => code}}}})
       when code in ["BuyPopper", "GameFull", "Blocked"],
       do: false

  defp refused?({:error, {:refused, _}}), do: true

  defp refused?({:error, {:http, status, _}})
       when status in 400..499 and status not in [401, 403],
       do: true

  defp refused?(_), do: false

  defp email_key(email) do
    secret = TriviaRelayWeb.Endpoint.config(:secret_key_base)
    normalized = email |> String.trim() |> String.downcase()
    :crypto.mac(:hmac, :sha256, secret, normalized)
  end
end
