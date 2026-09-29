defmodule TriviaRelay.Cache do
  @moduledoc """
  A few seconds' memory of what Sporcle answered, so a screen that polls (the games
  list, every 15 s per phone) or a list everybody opens (the popular packs) doesn't cost
  a Sporcle call each time.

  Keys are chosen by the caller, and anything that answers for one player is keyed by
  who they are *and* the credentials they proved it with (`TriviaRelay.Sporcle.Cred.key/1`),
  so one player's answer is never served to somebody else. Only successes are kept.

  One ETS table, owned by `TriviaRelay.RateLimit` (which is started with the relay and
  sweeps it every minute). Without the table (not started, as in some unit tests) every
  fetch is a miss and nothing is kept. The table is bounded: past `@max_entries`
  nothing new is kept until the sweep makes room.
  """

  @table __MODULE__
  @max_entries 20_000

  @doc false
  def new, do: :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])

  @doc """
  The value kept under `key` if it is younger than `ttl_ms`, else `fun.()`, kept when it
  is `{:ok, _}`.
  """
  @spec fetch(term(), pos_integer(), (-> {:ok, term()} | term())) :: {:ok, term()} | term()
  def fetch(key, ttl_ms, fun) do
    now = now_ms()

    case enabled?() && lookup(key) do
      {:ok, value, expires} when expires > now ->
        {:ok, value}

      _ ->
        fun.() |> keep(key, now + ttl_ms)
    end
  end

  defp keep({:ok, value} = ok, key, expires) do
    if enabled?(), do: put(key, value, expires)
    ok
  end

  defp keep(other, _key, _expires), do: other

  @doc "Drops everything past its time. Run by `TriviaRelay.RateLimit`'s sweep."
  @spec sweep() :: non_neg_integer()
  def sweep do
    :ets.select_delete(@table, [{{:_, :_, :"$1"}, [{:<, :"$1", now_ms()}], [true]}])
  rescue
    ArgumentError -> 0
  end

  @doc "Forgets everything. Tests only."
  @spec clear() :: :ok
  def clear do
    :ets.delete_all_objects(@table)
    :ok
  rescue
    ArgumentError -> :ok
  end

  # Off in tests (test.exs), except where a test turns it on, so that stubs answer.
  defp enabled?, do: Application.get_env(:trivia_relay, :cache_enabled, true)

  defp lookup(key) do
    case :ets.lookup(@table, key) do
      [{^key, value, expires}] -> {:ok, value, expires}
      [] -> :miss
    end
  rescue
    ArgumentError -> :miss
  end

  defp put(key, value, expires) do
    if :ets.info(@table, :size) < @max_entries, do: :ets.insert(@table, {key, value, expires})
  rescue
    ArgumentError -> false
  end

  defp now_ms, do: System.monotonic_time(:millisecond)
end
