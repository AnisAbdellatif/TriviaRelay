defmodule TriviaRelay.SeatsTest do
  # Changes the relay's seat limit, which every other test's seats go through.
  use ExUnit.Case, async: false

  alias TriviaRelay.Seats
  alias TriviaRelay.Sporcle.Cred

  setup do
    before = Application.get_env(:trivia_relay, :max_seats)
    on_exit(fn -> restore(before) end)
  end

  defp restore(nil), do: Application.delete_env(:trivia_relay, :max_seats)
  defp restore(value), do: Application.put_env(:trivia_relay, :max_seats, value)

  test "a full relay refuses a seat before asking Sporcle for one" do
    Application.put_env(:trivia_relay, :max_seats, 0)
    # No Sporcle stub is in place: a call to Sporcle would fail the test.
    cred = %Cred{player_id: "joinPlayer", token: "t0k3n", device_id: "d3v", handle: "Joiner"}

    assert Seats.join(cred, "624949") == {:error, :seats_full}

    options = %{"questions_per_game" => 5, "question_seconds" => 15, "audience" => "private"}
    assert Seats.host(cred, 156_070, options) == {:error, :seats_full}
  end
end
