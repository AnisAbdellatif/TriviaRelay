defmodule TriviaRelayWeb.SeatChannelTest do
  use TriviaRelayWeb.ChannelCase, async: true

  alias TriviaRelay.Protocol
  alias TriviaRelay.Seats.Seat
  alias TriviaRelayWeb.{SeatChannel, UserSocket}

  defp join_seat(%{id: id, token: token}, params \\ %{}) do
    socket(UserSocket, nil, %{ip: "198.51.100.1"})
    |> subscribe_and_join(
      SeatChannel,
      "seat:" <> id,
      Map.merge(%{"seat_token" => token, "protocol_version" => Protocol.major()}, params)
    )
  end

  test "a phone joins with its seat token and gets a snapshot at once" do
    seat = start_seat()
    assert {:ok, _, _socket} = join_seat(seat)
    assert_push "state", %{status: :connecting, phase: :lobby, game_code: "624949"}
  end

  test "snapshots follow what Sporcle sends" do
    seat = start_seat()
    {:ok, _, _} = join_seat(seat)
    assert_push "state", _

    lobby(seat.seat)
    assert_push "state", %{status: :live, players: [_, _], you: %{peer_id: 2, host: false}}

    sporcle(seat.seat, "game_question", %{"questionIndex" => 0, "question" => "🇮🇳"})

    assert_push "state", %{
      phase: :question,
      question: %{text: "🇮🇳"},
      deadline: deadline,
      server_time: now
    }

    assert (deadline - now) in 14_000..15_000
  end

  test "intents reach Sporcle as the official app's messages, and refusals come back" do
    seat = start_seat()
    {:ok, _, socket} = join_seat(seat)
    lobby(seat.seat)

    ref = push(socket, "ready", %{"ready" => true})
    assert_reply ref, :ok
    assert_receive {:sent, "player_update", %{readyForGame: true}}

    ref = push(socket, "start", %{})
    assert_reply ref, :error, %{code: "not_host"}

    sporcle(seat.seat, "game_question", %{"questionIndex" => 0, "question" => "?"})
    ref = push(socket, "answer", %{"text" => "india", "wager" => 9})
    assert_reply ref, :error, %{code: "invalid_wager"}

    ref = push(socket, "answer", %{"text" => "india", "wager" => 5})
    assert_reply ref, :ok

    assert_receive {:sent, "answer_question",
                    %{questionIndex: 0, wagerAmount: 5, guessText: "india"}}
  end

  test "a wrong or foreign token is refused" do
    seat = start_seat()
    other = start_seat()

    assert {:error, %{code: "invalid_token"}} = join_seat(%{seat | token: "nope"})
    assert {:error, %{code: "invalid_token"}} = join_seat(%{seat | token: other.token})
  end

  test "an app from another protocol major is refused" do
    assert {:error, %{code: "version_mismatch"}} =
             join_seat(start_seat(), %{"protocol_version" => Protocol.major() + 1})
  end

  test "a seat that has ended is not found" do
    seat = start_seat()
    ref = Process.monitor(seat.seat)
    Seat.close(seat.seat, "expired")
    assert_receive {:DOWN, ^ref, _, _, _}
    assert {:error, %{code: "seat_not_found"}} = join_seat(seat)
  end

  test "leaving closes the seat and leaves the Sporcle game" do
    seat = start_seat()
    {:ok, _, socket} = join_seat(seat)
    push(socket, "leave", %{})
    assert_push "seat_closed", %{reason: "left"}
    assert_receive :upstream_closed
  end

  test "the host removing the player ends the seat" do
    seat = start_seat()
    {:ok, _, _} = join_seat(seat)
    lobby(seat.seat)
    sporcle(seat.seat, "bounce", %{"peerId" => 2, "playerId" => "sporcle_id//joinPlayer"})
    assert_push "seat_closed", %{reason: "removed"}
    assert_receive :upstream_closed
  end
end
