defmodule TriviaRelay.Seats.Drain do
  @moduledoc """
  Closes every seat out loud when the server is going down.

  Seats live in memory, so a restart ends them all, and with them every relayed player's
  place in their Sporcle game. What this avoids is ending them *silently*: the
  supervisor stops children in reverse order, so this process, started last, terminates
  before the endpoint. It closes every seat with `shutdown`, then waits long enough for
  those pushes to reach the sockets still open, so a phone says so instead of
  reconnecting into `seat_not_found`.

  `SIGUSR2` asks for the same thing without stopping, for a deploy to send before the
  new container takes over (kamal-proxy cuts the old container's WebSockets at the
  switch, before `SIGTERM` could be heard). Copied from FazouraParty's `Rooms.Drain`.

  `config :trivia_relay, :drain_ms` sets how long to wait for those pushes (0 closes
  without waiting, which is what tests want).
  """

  use GenServer

  require Logger

  alias TriviaRelay.Seats

  @default_drain_ms 500

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Child spec with a shutdown budget that outlasts the drain wait."
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: drain_ms(opts) + 5_000
    }
  end

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    listen_for_signal()
    {:ok, %{drain_ms: drain_ms(opts)}}
  end

  @impl true
  def handle_info(:drain, state) do
    case Seats.close_all("shutdown") do
      0 -> :ok
      count -> Logger.info("closing #{count} seat(s): a new server is taking over")
    end

    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state) do
    case Seats.close_all("shutdown") do
      0 ->
        :ok

      count ->
        Logger.info("closing #{count} seat(s) before shutdown")
        if state.drain_ms > 0, do: Process.sleep(state.drain_ms)
        :ok
    end
  end

  # The runtime delivers OS signals it handles as events to `:erl_signal_server`; the
  # handler there is ours for SIGUSR2, and once only, however often this restarts.
  defp listen_for_signal do
    :ok = :os.set_signal(:sigusr2, :handle)

    if __MODULE__.Signal not in :gen_event.which_handlers(:erl_signal_server) do
      :ok = :gen_event.add_handler(:erl_signal_server, __MODULE__.Signal, [])
    end
  end

  defp drain_ms(opts) do
    Keyword.get_lazy(opts, :drain_ms, fn ->
      Application.get_env(:trivia_relay, :drain_ms, @default_drain_ms)
    end)
  end
end

defmodule TriviaRelay.Seats.Drain.Signal do
  @moduledoc false
  # SIGUSR2, as `:erl_signal_server` hands it on: ask `TriviaRelay.Seats.Drain` to close
  # every seat. Every other signal is left to the runtime's own handler.

  @behaviour :gen_event

  @impl true
  def init(_args), do: {:ok, nil}

  @impl true
  def handle_event(:sigusr2, state) do
    if pid = Process.whereis(TriviaRelay.Seats.Drain), do: send(pid, :drain)
    {:ok, state}
  end

  def handle_event(_signal, state), do: {:ok, state}

  @impl true
  def handle_call(_request, state), do: {:ok, :ok, state}
end
