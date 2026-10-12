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

    # The first question comes after the start's countdown.
    assert (deadline - now) in 19_000..20_000
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

    ref = push(socket, "rate", %{"rating" => 1})
    assert_reply ref, :ok
    assert_receive {:sent, "rate_question", %{questionIndex: 0, rating: 1}}

    ref = push(socket, "remove", %{"peer_id" => 1, "ban" => true})
    assert_reply ref, :error, %{code: "not_host"}
  end

  test "the host's player menu and return to the lobby reach Sporcle" do
    seat = start_seat()
    {:ok, _, socket} = join_seat(seat)
    lobby(seat.seat)
    sporcle(seat.seat, "promote_to_host", %{})
    assert_push "state", %{you: %{host: true}, notice: %{kind: "promoted"}}

    ref = push(socket, "remove", %{"peer_id" => 1, "ban" => false})
    assert_reply ref, :ok

    assert_receive {:sent, "bounce",
                    %{peerId: 1, playerId: "sporcle_id//hostPlayer", noReturn: false}}

    ref = push(socket, "make_host", %{"peer_id" => 1})
    assert_reply ref, :ok
    assert_receive {:sent, "promote_new_host", %{peerId: 1}}

    ref = push(socket, "make_host", %{"peer_id" => 2})
    assert_reply ref, :error, %{code: "invalid_intent"}

    sporcle(seat.seat, "game_question", %{"questionIndex" => 0, "question" => "?"})
    ref = push(socket, "to_lobby", %{})
    assert_reply ref, :ok
    assert_receive {:sent, "go_to_lobby", :none}
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

  describe "the host removing the player" do
    # Sporcle sends `bounce` to the removed player only; the official app reads just
    # `noReturn` and `reject` from it (decompiled).
    for {name, payload, can_rejoin} <- [
          {"ejects: they may join again", %{"noReturn" => false}, true},
          {"kicks: they may not", %{"peerId" => 2, "noReturn" => true}, false},
          {"refuses a kicked player coming back", %{"reject" => true}, false},
          {"with nothing said", nil, true}
        ] do
      test "#{name}" do
        seat = start_seat()
        {:ok, _, _} = join_seat(seat)
        lobby(seat.seat)
        sporcle(seat.seat, "bounce", unquote(Macro.escape(payload)))

        assert_push "seat_closed", %{reason: "removed", can_rejoin: unquote(can_rejoin)}
        assert_receive :upstream_closed
      end
    end
  end

  test "intents are limited per seat, whichever phone sends them" do
    seat = start_seat()
    {:ok, _, first} = join_seat(seat)
    lobby(seat.seat)

    # A second phone on its own socket (a transport of its own, forwarding to this test):
    # the per-socket meter alone would let it through.
    test = self()
    transport = spawn_link(fn -> forward(test) end)

    {:ok, _, second} =
      %{socket(UserSocket, nil, %{ip: "198.51.100.2"}) | transport_pid: transport}
      |> subscribe_and_join(SeatChannel, "seat:" <> seat.id, %{
        "seat_token" => seat.token,
        "protocol_version" => Protocol.major()
      })

    for _ <- 1..30 do
      ref = push(first, "draft", %{"text" => "a", "wager" => 1})
      assert_reply ref, :ok
      ref = push(second, "draft", %{"text" => "b", "wager" => 1})
      assert_reply ref, :ok
    end

    ref = push(second, "draft", %{"text" => "c", "wager" => 1})
    assert_reply ref, :error, %{code: "rate_limited"}
  end

  defp forward(test) do
    receive do
      message ->
        send(test, message)
        forward(test)
    end
  end

  test "a ready that changes nothing doesn't reach Sporcle" do
    seat = start_seat()
    {:ok, _, socket} = join_seat(seat)
    lobby(seat.seat)

    ref = push(socket, "ready", %{"ready" => true})
    assert_reply ref, :ok
    assert_receive {:sent, "player_update", %{readyForGame: true}}

    ref = push(socket, "ready", %{"ready" => true})
    assert_reply ref, :ok
    refute_receive {:sent, "player_update", _}, 100
  end

  test "a phone pushed off its seat by newer ones is closed without a word" do
    seat = start_seat(max_phones: 1)
    {:ok, _, first} = join_seat(seat)
    Process.unlink(first.channel_pid)
    ref = Process.monitor(first.channel_pid)

    {:ok, _, _second} = join_seat(seat)
    assert_receive {:DOWN, ^ref, _, _, :normal}
    refute_received %Phoenix.Socket.Message{event: "seat_closed"}
  end

  test "the same player taking a new seat closes the old one as left, replaced" do
    old = start_seat()
    {:ok, _, _} = join_seat(old)
    _new = start_seat(me: old.me)
    assert_push "seat_closed", %{reason: "left", replaced: true}
  end

  describe "the chat" do
    test "opens with a phone's chat screen, and closes when the last phone with it goes" do
      seat = start_seat()
      {:ok, _, first} = join_seat(seat)
      {:ok, _, second} = join_seat(seat)
      lobby(seat.seat)

      ref = push(first, "chat_open", %{})
      assert_reply ref, :ok
      assert_receive {:sent, "chat_open", :none}
      assert_push "state", %{chat: %{open: true}}

      ref = push(second, "chat_open", %{})
      assert_reply ref, :ok
      refute_receive {:sent, "chat_open", _}, 50

      ref = push(first, "chat_close", %{})
      assert_reply ref, :ok
      refute_receive {:sent, "chat_close", _}, 50

      Process.unlink(second.channel_pid)
      close(second)
      assert_receive {:sent, "chat_close", :none}
    end

    test "waits for the seat to be in the game before opening" do
      seat = start_seat()
      {:ok, _, socket} = join_seat(seat)
      ref = push(socket, "chat_open", %{})
      assert_reply ref, :ok
      refute_receive {:sent, "chat_open", _}, 50

      lobby(seat.seat)
      assert_receive {:sent, "chat_open", :none}
    end

    test "messages reach Sporcle, at most five in ten seconds a seat" do
      seat = start_seat()
      {:ok, _, socket} = join_seat(seat)
      lobby(seat.seat)

      for i <- 1..5 do
        ref = push(socket, "chat_send", %{"text" => "hi #{i}"})
        assert_reply ref, :ok
        assert_receive {:sent, "chat_message", %{message: %{"text" => "hi " <> _, "_id" => id}}}
        assert id =~ ~r/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/
      end

      ref = push(socket, "chat_send", %{"text" => "one more"})
      assert_reply ref, :error, %{code: "rate_limited"}
      refute_receive {:sent, "chat_message", _}, 50
    end
  end

  test "a honk goes to that player alone, from this seat's peer" do
    seat = start_seat()
    {:ok, _, socket} = join_seat(seat)
    lobby(seat.seat)

    ref = push(socket, "honk", %{"peer_id" => 1})
    assert_reply ref, :ok
    assert_receive {:sent_to, 1, 2, "honk", %{peerId: 2, honk_type: "goose"}}
    assert_receive {:sent, "send_u2u", %{peerId: 1, type: "goose"}}

    ref = push(socket, "honk", %{"peer_id" => 1})
    assert_reply ref, :error, %{code: "rate_limited"}

    sporcle(seat.seat, "honk", %{"peerId" => 1, "honk_type" => "clap"})
    assert_push "state", %{reactions: [%{peer_id: 1, type: "clap"}]}
  end

  test "a seat taken with Party Poppers says how many are left as they are spent" do
    seat = start_seat(poppers: 3)
    {:ok, _, _} = join_seat(seat)
    assert_push "state", %{you: %{poppers: 3}}
    lobby(seat.seat)
    sporcle(seat.seat, "popper_spent", nil)
    assert_push "state", %{you: %{poppers: 2}, notice: %{kind: "popper_spent"}}
  end
end
