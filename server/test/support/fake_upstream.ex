defmodule TriviaRelay.FakeUpstream do
  @moduledoc """
  Stands in for `TriviaRelay.Sporcle.Upstream` (the GameLift socket) in tests.

  The test that owns it is named in the player session, as `"test_pid"` (a pid, or the
  string `:erlang.pid_to_list/1` makes of one, for sessions that come through a stubbed
  REST response). It hears `{:fake_upstream, pid, owner}` when a seat starts one,
  `{:sent, event, payload}` for every message the seat sends Sporcle (`{:sent_to, target,
  sender, event, payload}` for one sent to a single player), and
  `:upstream_closed`. To play Sporcle's side, the test sends the seat
  `{:upstream, label, {:event, name, payload, sender}}` itself (`sender` `-1` for a server
  message, a peer id for a forged `sendTo`; the `sporcle/3,4` helpers do this).
  """

  def start_link(opts) do
    test = test_pid(opts[:session]["test_pid"])
    owner = Keyword.fetch!(opts, :owner)
    pid = spawn_link(fn -> loop(test) end)
    send(test, {:fake_upstream, pid, owner, opts[:player]})
    {:ok, pid}
  end

  def send_event(pid, event, payload \\ :none) do
    send(pid, {:send, event, payload})
    :ok
  end

  def cast_event(pid, event, payload \\ :none), do: send_event(pid, event, payload)

  def cast_event_to(pid, target, sender, event, payload) do
    send(pid, {:send_to, target, sender, event, payload})
    :ok
  end

  def close(pid), do: send(pid, :close)

  defp loop(test) do
    receive do
      {:send, event, payload} ->
        send(test, {:sent, event, payload})
        loop(test)

      {:send_to, target, sender, event, payload} ->
        send(test, {:sent_to, target, sender, event, payload})
        loop(test)

      :close ->
        send(test, :upstream_closed)
    end
  end

  defp test_pid(pid) when is_pid(pid), do: pid
  defp test_pid(pid) when is_binary(pid), do: :erlang.list_to_pid(String.to_charlist(pid))
end
