defmodule TriviaRelay.Sporcle.Http do
  @moduledoc """
  Every request the relay makes to Sporcle goes through here, so tests can put a stub in
  front of all of them (`config :trivia_relay, :sporcle_http, plug: {Req.Test, …}`).
  Nothing is retried: creating or joining a game reserves a player session each time.

  Every request is bounded, so a slow Sporcle can't pile up the relay's processes and
  sockets behind it:
    * at most 40 at once across the relay; past that a request fails at once with
      `{:error, :busy}`, before reaching Sporcle (the pool holds 50 connections);
    * 3 s to get a connection from the pool, 15 s between bytes, and 20 s for the whole
      request, connecting included, after which it is abandoned with
      `{:error, :timeout}`.
  """

  alias TriviaRelay.RateLimit

  @max_in_flight 40
  @pool_timeout_ms 3_000
  @receive_timeout_ms 15_000
  @timeout_ms 20_000

  @spec request(keyword()) :: {:ok, Req.Response.t()} | {:error, term()}
  def request(opts) do
    opts =
      [
        retry: false,
        finch: [pool_timeout: @pool_timeout_ms],
        receive_timeout: @receive_timeout_ms
      ]
      |> Keyword.merge(opts)
      |> Keyword.merge(Application.get_env(:trivia_relay, :sporcle_http, []))

    max = Application.get_env(:trivia_relay, :sporcle_max_in_flight, @max_in_flight)

    case RateLimit.hold(:sporcle_in_flight, "all", max) do
      :ok ->
        try do
          within(Application.get_env(:trivia_relay, :sporcle_timeout_ms, @timeout_ms), opts)
        after
          RateLimit.release(:sporcle_in_flight, "all")
        end

      {:error, :rate_limited} ->
        {:error, :busy}
    end
  end

  # The whole request, or `{:error, :timeout}` once `timeout` has passed. The task runs
  # as this process's (`$callers`), so a test's Req.Test stub still answers it.
  defp within(timeout, opts) do
    task = Task.async(fn -> Req.request(opts) end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, result} -> result
      {:exit, reason} -> {:error, {:exit, reason}}
      nil -> {:error, :timeout}
    end
  end
end
