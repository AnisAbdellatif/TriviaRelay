defmodule TriviaRelay.RateLimitTest do
  use ExUnit.Case, async: true

  alias TriviaRelay.RateLimit

  defp bucket, do: :"test_#{System.unique_integer([:positive])}"

  test "check_all counts every key, and is over when any is" do
    b = bucket()
    assert RateLimit.check_all(b, [{"narrow", 5}, {"wide", 1}], 60_000) == :ok
    assert RateLimit.check_all(b, [{"narrow", 5}, {"wide", 1}], 60_000) == {:error, :rate_limited}
    assert RateLimit.exceeded?(b, "narrow", 2, 60_000)
  end

  test "a hold lasts until it is released" do
    b = bucket()
    assert RateLimit.hold(b, "k", 2) == :ok
    assert RateLimit.hold(b, "k", 2) == :ok
    assert RateLimit.hold(b, "k", 2) == {:error, :rate_limited}
    assert RateLimit.held(b, "k") == 2

    RateLimit.release(b, "k")
    wait_until(fn -> RateLimit.held(b, "k") == 1 end)
    assert RateLimit.hold(b, "k", 2) == :ok
  end

  test "a hold ends with the process that took it, however it ends" do
    b = bucket()
    test = self()

    holder =
      spawn(fn ->
        send(test, {:held, RateLimit.hold(b, "k", 1)})
        Process.sleep(:infinity)
      end)

    assert_receive {:held, :ok}
    assert RateLimit.hold(b, "k", 1) == {:error, :rate_limited}

    Process.exit(holder, :kill)
    wait_until(fn -> RateLimit.held(b, "k") == 0 end)
    assert RateLimit.hold(b, "k", 1) == :ok
  end

  defp wait_until(fun, tries \\ 50) do
    cond do
      fun.() -> :ok
      tries == 0 -> flunk("never happened")
      true -> Process.sleep(10) && wait_until(fun, tries - 1)
    end
  end
end
