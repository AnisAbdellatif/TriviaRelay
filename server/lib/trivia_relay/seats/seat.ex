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
  player the way the official app does (`State.due/2`).

  The seat ends when the phone leaves, the hold runs out, the host removes the player,
  or the server shuts down; every attached phone is told why (`{:seat_closed, reason}`).
  If the upstream socket fails, the seat stays up as `lost` so the phone can say so
  (rejoining Sporcle from here is a later step).
  """

  use GenServer, restart: :temporary

  alias TriviaRelay.Seats.{Intents, State, View}

  @broadcast_interval_ms 100
  @default_hold_ms 300_000

  def constants, do: %{"broadcast_interval_ms" => @broadcast_interval_ms}

  @doc """
  Options: `:id`, `:game_code`, `:me` (the Sporcle id, `sporcle_id//…`), `:session`
  (the `playerSession` from createGame or joinGame), `:player` (the login JSON), and
  optionally `:now`, `:hold_ms`, `:broadcast_interval_ms` and `:upstream` (a module with
  the `Upstream` API, for tests).
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

    {:ok, pid} =
      upstream.start_link(
        owner: self(),
        label: opts.id,
        session: opts.session,
        player: opts.player
      )

    state = %{
      id: opts.id,
      game_code: opts.game_code,
      state: State.new(opts.me),
      now: now,
      upstream_mod: upstream,
      upstream: pid,
      conns: %{},
      hold_ms: Map.get_lazy(opts, :hold_ms, &hold_ms/0),
      hold_timer: nil,
      deadline_timer: nil,
      interval: Map.get_lazy(opts, :broadcast_interval_ms, &broadcast_interval_ms/0),
      flush: nil,
      last_broadcast_at: nil
    }

    # Nobody is attached yet: the phone that asked for this seat has the hold to arrive.
    {:ok, start_hold(state)}
  end

  @impl true
  def handle_call({:attach, pid}, _from, s) do
    s =
      if Map.has_key?(s.conns, pid),
        do: s,
        else: %{s | conns: Map.put(s.conns, pid, Process.monitor(pid))}

    s = cancel_hold(s)
    send(pid, {:seat_state, View.snapshot(s.state, s.game_code, s.now.())})
    {:reply, :ok, s}
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
    state = State.apply_event(s.state, event, payload, s.now.())
    s = %{s | state: state} |> schedule_deadline() |> broadcast()

    if state.status == :removed,
      do: {:stop, :normal, close_seat(s, "removed")},
      else: {:noreply, s}
  end

  def handle_info({:upstream, _label, {:closed, _reason}}, s) do
    {:noreply, %{s | state: State.lost(s.state), upstream: nil} |> broadcast()}
  end

  def handle_info({:upstream, _label, _other}, s), do: {:noreply, s}

  def handle_info({:DOWN, _ref, :process, pid, _reason}, s) do
    case Map.pop(s.conns, pid) do
      {nil, _} -> {:noreply, s}
      {_ref, conns} when conns == %{} -> {:noreply, start_hold(%{s | conns: conns})}
      {_ref, conns} -> {:noreply, %{s | conns: conns}}
    end
  end

  def handle_info(:hold_expired, s), do: {:stop, :normal, close_seat(s, "expired")}

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
    view = View.snapshot(s.state, s.game_code, s.now.())
    Enum.each(Map.keys(s.conns), &send(&1, {:seat_state, view}))
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

  ## Helpers

  defp send_upstream(%{upstream: nil}, _message), do: :ok

  defp send_upstream(s, {event, payload}) do
    _ = s.upstream_mod.send_event(s.upstream, event, payload)
    :ok
  end

  defp close_seat(s, reason) do
    Enum.each(Map.keys(s.conns), &send(&1, {:seat_closed, reason}))
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

  defp start_hold(s) do
    s = cancel_hold(s)
    %{s | hold_timer: Process.send_after(self(), :hold_expired, s.hold_ms)}
  end

  defp cancel_hold(%{hold_timer: nil} = s), do: s

  defp cancel_hold(s) do
    Process.cancel_timer(s.hold_timer)
    %{s | hold_timer: nil}
  end

  defp hold_ms, do: Application.get_env(:trivia_relay, :seat_hold_ms, @default_hold_ms)

  defp broadcast_interval_ms,
    do: Application.get_env(:trivia_relay, :broadcast_interval_ms, @broadcast_interval_ms)
end
