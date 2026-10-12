defmodule TriviaRelayWeb.UserSocketTest do
  # The meters are global (one ETS table, one switch), so these run on their own.
  use ExUnit.Case, async: false

  alias TriviaRelay.RateLimit
  alias TriviaRelayWeb.UserSocket

  setup do
    Application.put_env(:trivia_relay, :rate_limit_enabled, true)
    RateLimit.reset()

    on_exit(fn ->
      Application.put_env(:trivia_relay, :rate_limit_enabled, false)
      RateLimit.reset()
    end)
  end

  defp info(address), do: %{peer_data: %{address: address, port: 1, ssl_cert: nil}}

  # connect/3 runs in the process that becomes the socket; so does this.
  defp open(address) do
    test = self()

    pid =
      spawn(fn ->
        send(
          test,
          {:connected, self(), UserSocket.connect(%{}, %Phoenix.Socket{}, info(address))}
        )

        Process.sleep(:infinity)
      end)

    assert_receive {:connected, ^pid, result}
    {pid, result}
  end

  test "an address may hold only so many sockets at once" do
    address = {192, 0, 2, 1}
    sockets = for _ <- 1..40, do: open(address)
    assert Enum.all?(sockets, &match?({_, {:ok, _}}, &1))

    assert {_, :error} = open(address)
    assert {_, {:ok, _}} = open({192, 0, 2, 2})

    # One closes; its place is free again.
    [{pid, _} | _] = sockets
    Process.exit(pid, :kill)
    wait_until(fn -> RateLimit.held(:open_sockets, "192.0.2.1") < 40 end)
    assert {_, {:ok, _}} = open(address)
  end

  test "an IPv6 /48 may hold four times what one /64 may" do
    results =
      for net <- 1..5, n <- 1..40 do
        {_, result} = open({0x2001, 0xDB8, 5, net, 0, 0, 0, n})
        result
      end

    {first_four, fifth} = Enum.split(results, 160)
    assert Enum.all?(first_four, &match?({:ok, _}, &1))
    assert Enum.all?(fifth, &(&1 == :error))
  end

  test "an address may open only so many a minute" do
    # Each closes at once, so only the rate stops them.
    results =
      for _ <- 1..61 do
        {pid, result} = open({192, 0, 2, 9})
        Process.exit(pid, :kill)
        result
      end

    assert Enum.count(results, &match?({:ok, _}, &1)) == 60
    assert List.last(results) == :error
  end

  defp wait_until(fun, tries \\ 50) do
    cond do
      fun.() -> :ok
      tries == 0 -> flunk("never happened")
      true -> Process.sleep(10) && wait_until(fun, tries - 1)
    end
  end
end
