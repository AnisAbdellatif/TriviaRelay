defmodule TriviaRelay.Seats do
  @moduledoc """
  Taking a seat in a Sporcle game for a phone (`protocol/PROTOCOL.md` §3).

  Joining or hosting makes the Party REST call with the player's credentials, which are
  used for that call and not kept, then starts a `Seat` holding the player's GameLift
  connection. The phone gets back the seat's id and a signed seat token, joins
  `seat:<id>` with it, and presents the same token every time it reconnects.

  The relay holds at most `:max_seats` seats (default 2000); past that, taking a seat
  is refused with `{:error, :seats_full}` before anything is asked of Sporcle.
  """

  alias TriviaRelay.Seats.{Intents, Seat}
  alias TriviaRelay.Sporcle.{Api, Cred, Identity}

  @token_salt "seat"
  # A seat never outlives a day (`Seat`'s `:seat_max_ms`); its token need not either.
  @token_max_age 86_400
  @default_max_seats 2000

  @doc "How many seats the relay holds at most (`config :trivia_relay, :max_seats`)."
  def max_seats, do: Application.get_env(:trivia_relay, :max_seats, @default_max_seats)

  @doc """
  Joins the game `code`. Returns `{:ok, seat}` with `:id`, `:token`, `:game_code` and
  `:poppers`, the Party Poppers Sporcle says the player has (or nil).
  """
  def join(%Cred{} = cred, code, opts \\ []) do
    with :ok <- room(),
         {:ok, joined} <- Api.join_game(cred, code),
         {:ok, session} <- session(joined),
         {:ok, seat} <-
           start(cred, code, session, Identity.player(cred, false), [
             {:poppers, poppers(joined)} | opts
           ]) do
      {:ok, Map.put(seat, :poppers, poppers(joined))}
    end
  end

  @doc """
  Creates a game of pack `pack_id` with `options` (validated by
  `Intents.validate_options/1`) and seats its host. The options go both to `createGame`
  and into the host's login, which is where the game server reads them.
  """
  def host(%Cred{} = cred, pack_id, options, opts \\ []) do
    with {:ok, game_options} <- Intents.validate_options(options),
         :ok <- room(),
         {:ok, pack} <- Api.get_pack(cred, pack_id),
         {:ok, pack} <- found(pack),
         {:ok, game} <- Api.create_game(cred, pack, game_options),
         {:ok, session} <- session(game),
         {:ok, seat} <-
           start(cred, game["gameCode"], session, Identity.player(cred, true, game_options), [
             {:poppers, poppers(game)} | opts
           ]) do
      {:ok, Map.put(seat, :poppers, poppers(game))}
    end
  end

  # createGame and joinGame say how many Party Poppers the player has (confirmed live).
  defp poppers(%{"popper_count" => n}) when is_integer(n) and n >= 0, do: n
  defp poppers(_), do: nil

  @doc """
  Chooses pack `pack_id` in the lobby for the seat `seat_token` was issued for: the host
  changes the game's pack to it, anybody else votes for it (`Intents.change_pack/2`). The
  pack is fetched with the player's credentials, as for `host/4`.
  """
  def change_pack(%Cred{} = cred, seat_token, pack_id) do
    with {:ok, id} <- verify(seat_token),
         pid when is_pid(pid) <- whereis(id),
         {:ok, pack} <- Api.get_pack(cred, pack_id),
         {:ok, pack} <- found(pack),
         :ok <- Seat.change_pack(pid, pack) do
      :ok
    else
      nil -> {:error, :seat_not_found}
      {:error, "seat_not_found"} -> {:error, :seat_not_found}
      {:error, reason} when reason in [:invalid, :expired, :missing] -> {:error, :invalid_token}
      error -> error
    end
  end

  @doc """
  Whether `seat_token` names a running seat that is `cred`'s player's own (a player has
  one seat at a time, claimed in `TriviaRelay.Seats.Players`): `:ok`, or
  `{:error, :invalid_token | :seat_not_found}`. What the player asks the relay to do
  for the game they are in (inviting friends to it) is only done from there.
  """
  def owned(%Cred{} = cred, seat_token) do
    with {:ok, id} <- verify(seat_token),
         pid when is_pid(pid) <- whereis(id),
         [{^pid, _}] <- Registry.lookup(TriviaRelay.Seats.Players, Identity.sporcle_id(cred)) do
      :ok
    else
      {:error, _} -> {:error, :invalid_token}
      _ -> {:error, :seat_not_found}
    end
  end

  @doc "The running seat `id`, or nil."
  def whereis(id) do
    case Registry.lookup(TriviaRelay.Seats.Registry, id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def sign(id), do: Phoenix.Token.sign(TriviaRelayWeb.Endpoint, @token_salt, id)

  @doc "The seat id a token was issued for, if it is genuine and current."
  def verify(token) when is_binary(token) do
    Phoenix.Token.verify(TriviaRelayWeb.Endpoint, @token_salt, token, max_age: @token_max_age)
  end

  def verify(_), do: {:error, :invalid}

  @doc "Closes every seat with `reason`. Returns how many there were."
  def close_all(reason) do
    seats = DynamicSupervisor.which_children(TriviaRelay.Seats.Supervisor)
    Enum.each(seats, fn {_, pid, _, _} -> Seat.close(pid, reason) end)
    length(seats)
  end

  defp start(cred, code, session, player, opts) do
    id = Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)

    spec =
      {Seat,
       [id: id, game_code: code, me: Identity.sporcle_id(cred), session: session, player: player] ++
         opts}

    case DynamicSupervisor.start_child(TriviaRelay.Seats.Supervisor, spec) do
      {:ok, _pid} -> {:ok, %{id: id, token: sign(id), game_code: code}}
      {:error, :max_children} -> {:error, :seats_full}
      {:error, reason} -> {:error, {:seat_failed, reason}}
    end
  end

  # Checked before the Sporcle call, so a full relay does not have Sporcle seat a player
  # it cannot hold; the supervisor's `max_children` is what actually holds the line.
  defp room do
    %{active: active} = DynamicSupervisor.count_children(TriviaRelay.Seats.Supervisor)
    if active < max_seats(), do: :ok, else: {:error, :seats_full}
  end

  # createGame and joinGame answer 200 even when they refuse; what they refuse with has
  # no player session.
  defp session(%{"playerSession" => %{"DnsName" => _, "Port" => _, "PlayerSessionId" => _} = s}),
    do: {:ok, s}

  defp session(body), do: {:error, {:refused, body}}

  defp found(%{"id" => _} = pack), do: {:ok, pack}
  defp found(_), do: {:error, :pack_not_found}
end
