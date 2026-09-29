defmodule TriviaRelay.Seats.Seat do
  @moduledoc """
  One player's seat in one Sporcle game: the process that keeps the player's GameLift
  connection open while their phone comes and goes.

  It owns the `Upstream`, folds what arrives into a `State`, and sends every attached
  phone a snapshot (`View`) when something changed — paced like a Fazoura room, at most
  one per `broadcast_interval_ms`, the first after a quiet spell at once. Phones attach
  from the seat channel; the seat monitors each one.

  With no phone attached, the seat carries on for `:seat_hold_ms` (`SEAT_HOLD_SECONDS`,
  configured per deployment) and then leaves the game. Until then Sporcle sees a player
  who never went away, and when a question's time runs out the seat answers for the
  player the way the official app does (`State.due/2`). A seat no phone has attached to
  yet is held only for `:seat_attach_ms`: the phone that asked for it attaches at once.

  One player has one seat: a new seat for the same Sporcle account ends the old one
  (`left`, with `replaced: true`), and takes over what it had spent in the same game
  (`State.carry_over/2`). At most `:seat_max_phones` phones are attached at a time; the
  oldest makes way for a new one.

  The seat ends when the phone leaves, the hold runs out, the host removes the player,
  the same player takes another seat, it reaches `:seat_max_ms` (a seat token's life),
  or the server shuts down; every attached phone is told why
  (`{:seat_closed, %{reason: …}}`). If the upstream socket fails, the seat stays up as
  `lost` so the phone can say so (rejoining Sporcle from here is a later step).

  Sporcle's events are folded defensively (`State.apply_event/4` ignores what does not
  fit), and an event that still raises is dropped, keeping the state it found. Crash
  reports and `:sys.get_status/1` show a summary, never the players or their answers.
  """

  use GenServer, restart: :temporary

  require Logger

  alias TriviaRelay.Seats.{Intents, State, View}

  @broadcast_interval_ms 100
  @default_hold_ms 300_000
  @default_attach_ms 30_000
  # A seat token lives a day (`TriviaRelay.Seats`), and so does a seat.
  @default_max_ms 86_400_000
  @default_max_phones 3
  @players TriviaRelay.Seats.Players

  def constants, do: %{"broadcast_interval_ms" => @broadcast_interval_ms}

  @doc """
  Options: `:id`, `:game_code`, `:me` (the Sporcle id, `sporcle_id//…`), `:session`
  (the `playerSession` from createGame or joinGame), `:player` (the login JSON), and
  optionally `:now`, `:hold_ms`, `:attach_ms`, `:max_ms`, `:max_phones`,
  `:broadcast_interval_ms` and `:upstream` (a module with the `Upstream` API, for tests).
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, Map.new(opts), name: via(Keyword.fetch!(opts, :id)))
  end

  def via(id), do: {:via, Registry, {TriviaRelay.Seats.Registry, id}}

  @doc "Attaches a phone's channel process; it receives snapshots from now on."
  #
  # A seat found by id can end before the call reaches it (the registry lets go of it
  # after it has stopped): that is `{:error, "seat_not_found"}`, not a crash.
  def attach(seat, pid), do: call(seat, {:attach, pid})

  @doc "Runs an intent from the phone. Returns `:ok` or `{:error, code}`."
  def intent(seat, intent, payload), do: GenServer.call(seat, {:intent, intent, payload})

  @doc "Changes the lobby's pack (`Intents.change_pack/2`). Returns `:ok` or `{:error, code}`."
  def change_pack(seat, pack), do: call(seat, {:change_pack, pack})

  defp call(seat, message) do
    GenServer.call(seat, message)
  catch
    :exit, _ -> {:error, "seat_not_found"}
  end

  @doc "Ends the seat: leaves the game and tells every attached phone `reason`."
  def close(seat, reason), do: GenServer.cast(seat, {:close, reason})

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    now = Map.get(opts, :now, fn -> System.system_time(:millisecond) end)

    upstream =
      Map.get_lazy(opts, :upstream, fn ->
        Application.get_env(:trivia_relay, :upstream, TriviaRelay.Sporcle.Upstream)
      end)

    state = %{
      id: opts.id,
      game_code: opts.game_code,
      state: State.new(opts.me),
      now: now,
      upstream_mod: upstream,
      upstream: nil,
      conns: %{},
      attached: 0,
      hold_ms: Map.get_lazy(opts, :hold_ms, fn -> env(:seat_hold_ms, @default_hold_ms) end),
      attach_ms:
        Map.get_lazy(opts, :attach_ms, fn -> env(:seat_attach_ms, @default_attach_ms) end),
      max_phones:
        Map.get_lazy(opts, :max_phones, fn -> env(:seat_max_phones, @default_max_phones) end),
      hold_timer: nil,
      deadline_timer: nil,
      interval: Map.get_lazy(opts, :broadcast_interval_ms, &broadcast_interval_ms/0),
      flush: nil,
      last_broadcast_at: nil
    }

    Process.send_after(
      self(),
      :lifetime,
      Map.get_lazy(opts, :max_ms, fn -> env(:seat_max_ms, @default_max_ms) end)
    )

    # Nobody is attached yet: the phone that asked for this seat has a moment to arrive.
    # Taking the player's place (ending any seat they already have) and connecting to
    # Sporcle wait for `handle_continue/2`, so the seats supervisor is not held up.
    {:ok, start_hold(state), {:continue, {:connect, opts}}}
  end

  @impl true
  def handle_continue({:connect, opts}, s) do
    case claim(opts.me, s.game_code) do
      {:ok, earlier} ->
        state = if earlier, do: State.carry_over(s.state, earlier), else: s.state

        {:ok, pid} =
          s.upstream_mod.start_link(
            owner: self(),
            label: opts.id,
            session: opts.session,
            player: opts.player
          )

        {:noreply, %{s | state: state, upstream: pid}}

      :error ->
        {:stop, :normal, close_seat(s, "left", %{replaced: true})}
    end
  end

  @impl true
  def handle_call({:attach, pid}, _from, s) do
    s = if Map.has_key?(s.conns, pid), do: s, else: add_phone(s, pid)
    s = cancel_hold(s)
    if view = snapshot(s), do: send(pid, {:seat_state, view})
    {:reply, :ok, s}
  end

  # Another seat of the same player's is taking over: it gets what this one spent, if it
  # is in the same game, and this one ends.
  def handle_call({:replaced, game_code}, _from, s) do
    earlier = if game_code == s.game_code, do: s.state
    {:stop, :normal, {:ok, earlier}, close_seat(s, "left", %{replaced: true})}
  end

  def handle_call({:intent, "leave", _payload}, _from, s) do
    {:stop, :normal, :ok, close_seat(s, "left")}
  end

  def handle_call({:intent, intent, payload}, _from, s),
    do: reply_intent(Intents.handle(s.state, intent, payload || %{}), s)

  def handle_call({:change_pack, pack}, _from, s),
    do: reply_intent(Intents.change_pack(s.state, pack), s)

  @impl true
  def handle_cast({:close, reason}, s), do: {:stop, :normal, close_seat(s, reason)}

  @impl true
  def handle_info({:upstream, _label, {:event, event, payload}}, s) do
    state = fold(s, event, payload)
    s = %{s | state: state} |> schedule_deadline() |> broadcast()

    if state.status == :removed,
      do: {:stop, :normal, close_seat(s, "removed", %{can_rejoin: state.can_rejoin})},
      else: {:noreply, s}
  end

  def handle_info({:upstream, _label, {:closed, _reason}}, s) do
    {:noreply, %{s | state: State.lost(s.state), upstream: nil} |> broadcast()}
  end

  def handle_info({:upstream, _label, _other}, s), do: {:noreply, s}

  def handle_info({:DOWN, _ref, :process, pid, _reason}, s) do
    case Map.pop(s.conns, pid) do
      {nil, _} -> {:noreply, s}
      {_phone, conns} when conns == %{} -> {:noreply, start_hold(%{s | conns: conns})}
      {_phone, conns} -> {:noreply, %{s | conns: conns}}
    end
  end

  def handle_info(:hold_expired, s), do: {:stop, :normal, close_seat(s, "expired")}
  def handle_info(:lifetime, s), do: {:stop, :normal, close_seat(s, "expired")}

  def handle_info(:deadline, s) do
    now = s.now.()

    state =
      Enum.reduce(State.due(s.state, now), s.state, fn {:answer, index, text, wager}, state ->
        send_upstream(
          s,
          {"answer_question", %{questionIndex: index, wagerAmount: wager, guessText: text}}
        )

        State.sent(state, index, text, wager)
      end)

    if State.open?(state) do
      wait = state.deadline + State.reveal_grace_ms() - now
      Process.send_after(self(), {:overtime, State.index(state)}, max(wait, 0))
    end

    {:noreply, %{s | state: state, deadline_timer: nil} |> broadcast()}
  end

  def handle_info({:overtime, index}, s),
    do: {:noreply, %{s | state: State.overtime(s.state, index)} |> broadcast()}

  def handle_info(:flush, s) do
    if view = snapshot(s), do: Enum.each(Map.keys(s.conns), &send(&1, {:seat_state, view}))
    {:noreply, %{s | flush: nil, last_broadcast_at: System.monotonic_time(:millisecond)}}
  end

  def handle_info({:EXIT, pid, _reason}, %{upstream: pid} = s),
    do: {:noreply, %{s | state: State.lost(s.state), upstream: nil} |> broadcast()}

  def handle_info({:EXIT, _pid, _reason}, s), do: {:noreply, s}

  @impl true
  def terminate(_reason, s) do
    if s.upstream, do: s.upstream_mod.close(s.upstream)
    :ok
  end

  # Crash reports and `:sys.get_status/1` carry the other players' names, ids and answers,
  # and the login's device id, none of which belong in a log: they get a summary instead.
  @impl true
  def format_status(status) do
    Map.new(status, fn
      {:state, %{state: %State{}} = s} ->
        {:state,
         %{
           id: s.id,
           game_code: s.game_code,
           status: s.state.status,
           phase: s.state.phase,
           phones: map_size(s.conns),
           upstream: s.upstream
         }}

      {:state, _} ->
        {:state, :redacted}

      {:message, message} ->
        {:message, tag(message)}

      {:queue, queue} when is_list(queue) ->
        {:queue, Enum.map(queue, &tag/1)}

      {:log, _} ->
        {:log, []}

      {:reason, reason} ->
        {:reason, reason(reason)}

      other ->
        other
    end)
  end

  ## Helpers

  # One player, one seat: registers this seat as the player's, ending the seat they had
  # before. Returns that seat's state when it was in the same game.
  defp claim(me, game_code, attempts \\ 50)
  defp claim(_me, _game_code, 0), do: :error

  defp claim(me, game_code, attempts) do
    case Registry.register(@players, me, nil) do
      {:ok, _} ->
        {:ok, nil}

      {:error, {:already_registered, earlier}} ->
        taken = take_over(earlier, game_code)

        case claim(me, game_code, attempts - 1) do
          {:ok, nil} -> {:ok, taken}
          other -> other
        end
    end
  end

  defp take_over(earlier, game_code) do
    ref = Process.monitor(earlier)

    taken =
      try do
        {:ok, taken} = GenServer.call(earlier, {:replaced, game_code})
        taken
      catch
        :exit, _ ->
          Process.exit(earlier, :kill)
          nil
      end

    # The registry lets go of a seat once it has seen it stop, which may be a moment
    # after this process hears of it.
    receive do
      {:DOWN, ^ref, :process, _, _} -> Process.sleep(1)
    after
      5_000 -> Process.exit(earlier, :kill)
    end

    taken
  end

  # The oldest phone makes way once `max_phones` are attached: it is told nothing, and its
  # channel closes (`{:seat_detached}`), so it does not rejoin and push the new one out.
  defp add_phone(s, pid) do
    s =
      if map_size(s.conns) >= s.max_phones do
        {oldest, {ref, _}} = Enum.min_by(s.conns, fn {_pid, {_ref, n}} -> n end)
        Process.demonitor(ref, [:flush])
        send(oldest, :seat_detached)
        %{s | conns: Map.delete(s.conns, oldest)}
      else
        s
      end

    n = s.attached + 1
    %{s | conns: Map.put(s.conns, pid, {Process.monitor(pid), n}), attached: n}
  end

  # An event the state cannot take is dropped, and the state kept as it was. Only the
  # event's name is logged: the payload is other players'.
  defp fold(s, event, payload) do
    State.apply_event(s.state, event, payload, s.now.())
  rescue
    error ->
      Logger.warning(
        "seat #{s.id}: dropped Sporcle event #{inspect(String.slice(to_string(event), 0, 40))} " <>
          "(#{inspect(error.__struct__)})"
      )

      s.state
  end

  defp snapshot(s) do
    View.snapshot(s.state, s.game_code, s.now.())
  rescue
    error ->
      Logger.error("seat #{s.id}: could not build a snapshot (#{inspect(error.__struct__)})")
      nil
  end

  # Sends are casts: a stalled socket must not hold up the seat.
  defp send_upstream(%{upstream: nil}, _message), do: :ok

  defp send_upstream(s, {event, payload}) do
    _ = s.upstream_mod.cast_event(s.upstream, event, payload)
    :ok
  end

  defp close_seat(s, reason, details \\ %{}) do
    closed = Map.put(details, :reason, reason)
    Enum.each(Map.keys(s.conns), &send(&1, {:seat_closed, closed}))
    if s.upstream, do: s.upstream_mod.close(s.upstream)
    %{s | upstream: nil, conns: %{}}
  end

  # Asks for a snapshot. At most one goes out per interval; changes in between are
  # folded into it (a Fazoura room's pacing, PROTOCOL.md there §5.1).
  defp broadcast(%{flush: nil} = s) do
    now = System.monotonic_time(:millisecond)
    due = if s.last_broadcast_at, do: s.last_broadcast_at + s.interval - now, else: 0

    ref =
      if due <= 0 do
        send(self(), :flush)
        :now
      else
        Process.send_after(self(), :flush, due)
      end

    %{s | flush: ref}
  end

  defp broadcast(s), do: s

  defp reply_intent(result, s) do
    case result do
      {:ok, messages, state} ->
        Enum.each(messages, &send_upstream(s, &1))
        {:reply, :ok, s |> Map.put(:state, state) |> broadcast()}

      {:error, code} ->
        {:reply, {:error, code}, s}
    end
  end

  defp schedule_deadline(s) do
    if s.deadline_timer, do: Process.cancel_timer(s.deadline_timer)

    case s.state.deadline do
      nil ->
        %{s | deadline_timer: nil}

      deadline ->
        wait = max(deadline - s.now.(), 0)
        %{s | deadline_timer: Process.send_after(self(), :deadline, wait)}
    end
  end

  # A seat no phone has come to yet is held only briefly (`attach_ms`), never longer than
  # the hold itself.
  defp start_hold(s) do
    s = cancel_hold(s)
    hold = if s.attached == 0, do: min(s.attach_ms, s.hold_ms), else: s.hold_ms
    %{s | hold_timer: Process.send_after(self(), :hold_expired, hold)}
  end

  defp cancel_hold(%{hold_timer: nil} = s), do: s

  defp cancel_hold(s) do
    Process.cancel_timer(s.hold_timer)
    %{s | hold_timer: nil}
  end

  defp env(key, default), do: Application.get_env(:trivia_relay, key, default)

  defp tag({:"$gen_call", _from, request}), do: {:"$gen_call", tag(request)}
  defp tag({:"$gen_cast", request}), do: {:"$gen_cast", tag(request)}
  defp tag({:upstream, _label, {kind, name, _}}), do: {:upstream, kind, name}
  defp tag({:upstream, _label, message}), do: {:upstream, tag(message)}
  defp tag(message) when is_tuple(message) and tuple_size(message) > 0, do: elem(message, 0)
  defp tag(message) when is_atom(message), do: message
  defp tag(_message), do: :redacted

  # A crash's reason keeps the exception's kind and where it happened, not the terms.
  defp reason({%{__exception__: true} = error, stack}) when is_list(stack),
    do: {error.__struct__, Enum.map(stack, &frame/1)}

  defp reason({kind, stack}) when is_atom(kind) and is_list(stack),
    do: {kind, Enum.map(stack, &frame/1)}

  defp reason(reason) when is_atom(reason), do: reason
  defp reason(reason), do: tag(reason)

  defp frame({m, f, args, location}) when is_list(args), do: {m, f, length(args), location}
  defp frame(frame), do: frame

  defp broadcast_interval_ms,
    do: Application.get_env(:trivia_relay, :broadcast_interval_ms, @broadcast_interval_ms)
end
