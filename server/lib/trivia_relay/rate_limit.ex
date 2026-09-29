defmodule TriviaRelay.RateLimit do
  @moduledoc """
  Fixed-window request counting, per caller and bucket, and counts of what a caller holds
  at once.

  Logging in, searching packs and taking a seat each make calls to Sporcle on the
  caller's behalf and cost them nothing, so those endpoints are metered
  (`TriviaRelayWeb.Plugs.RateLimit`). Copied from FazouraParty's `Fazoura.RateLimit`.
  This is deliberately small: one ETS table of counters, swept every minute. It is a
  flood stop, not a fairness mechanism, and it counts per node — which is all a
  single-VPS deployment has.

  A fixed window lets a caller spend two windows' worth of requests across a boundary.
  That is accepted: the limits are far above real use, and the point is to bound the
  sustained rate, not to police bursts precisely.

  Holds (`hold/3`) count what is open rather than what happened: sockets per address,
  calls to Sporcle in flight. The process that holds is monitored, so a hold ends when
  it does, however it ends.

  This process also owns `TriviaRelay.Cache`'s table, so the edge's short-lived state has
  one owner and one sweep.
  """

  use GenServer

  @table __MODULE__
  # Counters are only useful for the window they belong to; sweep the stale ones every
  # minute so a flood of callers can't grow the table for long.
  @sweep_every :timer.minutes(1)

  @type bucket :: atom()

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc """
  Counts one request from `key` against `bucket`.

  `amount` is how much this one counts for — one request, or a request's bytes for a
  bucket that meters volume. Returns `:ok` while at or under `limit` per `window_ms`, and
  `{:error, :rate_limited}` once over. Missing table (not started, as in some unit
  tests) means no limiting rather than a crash.
  """
  @spec check(bucket(), String.t(), pos_integer(), pos_integer(), pos_integer()) ::
          :ok | {:error, :rate_limited}
  def check(bucket, key, limit, window_ms, amount \\ 1) do
    # The window's start in ms, so a sweep can compare it to wall-clock time without
    # knowing which window length any particular bucket used.
    window_start = div(now_ms(), window_ms) * window_ms

    counter = {bucket, key, window_start, window_ms}
    count = :ets.update_counter(@table, counter, {2, amount}, {counter, 0})

    if count > limit, do: {:error, :rate_limited}, else: :ok
  rescue
    ArgumentError -> :ok
  end

  @doc """
  `check/4` for each `{key, limit}` — one caller seen under several keys, such as an
  IPv6 /64 and its /48 (`TriviaRelayWeb.ClientIp.limits/2`). Every key is counted;
  over on any is over.
  """
  @spec check_all(bucket(), [{String.t(), pos_integer()}], pos_integer()) ::
          :ok | {:error, :rate_limited}
  def check_all(bucket, limits, window_ms) do
    limits
    |> Enum.map(fn {key, limit} -> check(bucket, key, limit, window_ms) end)
    |> Enum.find(:ok, &(&1 != :ok))
  end

  @doc """
  Whether `key` is already over `limit` in `bucket`'s current window, without counting
  anything. For meters that count failures: the attempt is let through or not by this,
  and only one that fails is counted with `check/4`.
  """
  @spec exceeded?(bucket(), String.t(), pos_integer(), pos_integer()) :: boolean()
  def exceeded?(bucket, key, limit, window_ms) do
    window_start = div(now_ms(), window_ms) * window_ms

    case :ets.lookup(@table, {bucket, key, window_start, window_ms}) do
      [{_key, count}] -> count >= limit
      [] -> false
    end
  rescue
    ArgumentError -> false
  end

  @doc "`exceeded?/4` over several `{key, limit}`: true when any is."
  @spec any_exceeded?(bucket(), [{String.t(), pos_integer()}], pos_integer()) :: boolean()
  def any_exceeded?(bucket, limits, window_ms),
    do: Enum.any?(limits, fn {key, limit} -> exceeded?(bucket, key, limit, window_ms) end)

  @doc """
  Takes one of at most `limit` places `key` may hold in `bucket` at once, for the
  calling process: `:ok`, or `{:error, :rate_limited}` when all are taken. The place is
  given back by `release/2`, or when the process exits.
  """
  @spec hold(bucket(), String.t(), pos_integer()) :: :ok | {:error, :rate_limited}
  def hold(bucket, key, limit) do
    counter = {:held, bucket, key}

    if :ets.update_counter(@table, counter, {2, 1}, {counter, 0}) > limit do
      give_back(counter)
      {:error, :rate_limited}
    else
      GenServer.cast(__MODULE__, {:monitor, self(), counter})
      :ok
    end
  rescue
    ArgumentError -> :ok
  end

  @doc "Gives back one place the calling process took with `hold/3`."
  @spec release(bucket(), String.t()) :: :ok
  def release(bucket, key) do
    GenServer.cast(__MODULE__, {:release, self(), {:held, bucket, key}})
  end

  @doc "How many places `key` holds in `bucket` now."
  @spec held(bucket(), String.t()) :: non_neg_integer()
  def held(bucket, key) do
    case :ets.lookup(@table, {:held, bucket, key}) do
      [{_key, count}] -> count
      [] -> 0
    end
  rescue
    ArgumentError -> 0
  end

  @doc "Forgets every counter (not the holds, which end with their processes). Tests only."
  @spec reset() :: :ok
  def reset do
    :ets.select_delete(@table, [{{{:_, :_, :_, :_}, :_}, [], [true]}])
    :ok
  rescue
    ArgumentError -> :ok
  end

  ## Callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    TriviaRelay.Cache.new()
    schedule_sweep()
    # Each held place is a monitor: `refs` finds the place a monitor holds, `owners` the
    # monitors a process holds a counter's places with.
    {:ok, %{refs: %{}, owners: %{}}}
  end

  @impl true
  def handle_cast({:monitor, pid, counter}, state) do
    ref = Process.monitor(pid)

    {:noreply,
     %{
       refs: Map.put(state.refs, ref, {pid, counter}),
       owners: Map.update(state.owners, {pid, counter}, [ref], &[ref | &1])
     }}
  end

  def handle_cast({:release, pid, counter}, state) do
    case Map.get(state.owners, {pid, counter}, []) do
      [] ->
        {:noreply, state}

      [ref | _] ->
        Process.demonitor(ref, [:flush])
        {:noreply, give_back(state, ref)}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state),
    do: {:noreply, give_back(state, ref)}

  def handle_info(:sweep, state) do
    _swept = sweep()
    _expired = TriviaRelay.Cache.sweep()
    schedule_sweep()
    {:noreply, state}
  end

  # A counter whose window has ended is spent. Each counter carries its own window's
  # length, so a bucket counted per day keeps its count all day rather than losing it
  # at the next sweep.
  @doc "Drops every counter whose window has ended. Run on a timer; public for tests."
  @spec sweep() :: non_neg_integer()
  def sweep do
    now = now_ms()

    :ets.select_delete(@table, [
      {{{:_, :_, :"$1", :"$2"}, :_}, [{:<, {:+, :"$1", :"$2"}, now}], [true]}
    ])
  rescue
    ArgumentError -> 0
  end

  # The place a monitor held, back.
  defp give_back(state, ref) do
    case Map.pop(state.refs, ref) do
      {nil, _refs} ->
        state

      {{_pid, counter} = owner, refs} ->
        give_back(counter)

        owners =
          case List.delete(Map.fetch!(state.owners, owner), ref) do
            [] -> Map.delete(state.owners, owner)
            rest -> Map.put(state.owners, owner, rest)
          end

        %{refs: refs, owners: owners}
    end
  end

  # One place back; the row goes once nothing is held, so the table only has rows for
  # callers holding something.
  defp give_back(counter) do
    if :ets.update_counter(@table, counter, {2, -1, 0, 0}) == 0,
      do: :ets.delete_object(@table, {counter, 0})
  end

  defp schedule_sweep, do: Process.send_after(self(), :sweep, @sweep_every)

  defp now_ms, do: System.system_time(:millisecond)
end
