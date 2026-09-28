defmodule TriviaRelay.Sporcle.FrameLog do
  @moduledoc """
  Writes one JSON line per frame, in either direction, to `logs/<name>.jsonl`.

  Each line carries the time since the log opened (`t_ms`), the wall clock, which
  connection it was (`conn`, since a rejoin opens a new one), the direction
  (`in`, `out`, or `ctl` for WebSocket control frames and connection events), the
  time since that connection last received anything (`gap_ms`), the decoded
  event and payload, every envelope field, and the raw bytes as hex. The raw
  bytes are the point: they let a log be re-read with a better decoder later.
  """

  use GenServer

  alias TriviaRelay.Sporcle.Envelope

  def start_link(name), do: GenServer.start_link(__MODULE__, name)

  def path(log), do: GenServer.call(log, :path)

  @doc "Records `entry` (a map) for connection `conn`. A nil log records nothing."
  def write(nil, _conn, _dir, _entry), do: :ok
  def write(log, conn, dir, entry), do: GenServer.cast(log, {:write, conn, dir, entry, now()})

  @impl true
  def init(name) do
    File.mkdir_p!("logs")
    path = Path.join("logs", name <> ".jsonl")
    {:ok, %{file: File.open!(path, [:append, :utf8]), path: path, t0: now(), last_in: %{}}}
  end

  @impl true
  def handle_call(:path, _from, state), do: {:reply, state.path, state}

  @impl true
  def handle_cast({:write, conn, dir, entry, at}, state) do
    gap = if last = state.last_in[conn], do: at - last
    last_in = if dir == "in", do: Map.put(state.last_in, conn, at), else: state.last_in

    line =
      entry
      |> Map.merge(%{
        t_ms: at - state.t0,
        at: DateTime.utc_now() |> DateTime.to_iso8601(),
        conn: conn,
        dir: dir,
        gap_ms: gap
      })
      |> Jason.encode!()

    IO.puts(state.file, line)
    {:noreply, %{state | last_in: last_in}}
  end

  @doc "A frame's envelope fields in a JSON-safe form, nested messages decoded where they parse."
  def fields(fields), do: Enum.map(fields, fn {num, value} -> [num, value(value)] end)

  defp value({:fixed32, n}), do: %{fixed32: n}
  defp value({:fixed64, n}), do: %{fixed64: n}
  defp value(n) when is_integer(n), do: n

  defp value(bin) when is_binary(bin) do
    cond do
      String.printable?(bin) -> bin
      match?({:ok, [_ | _]}, Envelope.fields(bin)) -> %{nested: nested(bin)}
      true -> %{hex: Base.encode16(bin, case: :lower)}
    end
  end

  defp nested(bin) do
    {:ok, fields} = Envelope.fields(bin)
    fields(fields)
  end

  defp now, do: System.monotonic_time(:millisecond)
end
