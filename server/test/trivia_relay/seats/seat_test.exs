defmodule TriviaRelay.Seats.SeatTest do
  use TriviaRelayWeb.ChannelCase, async: true

  alias TriviaRelay.Seats.{Seat, State}

  defp phone do
    test = self()
    spawn(fn -> receive_loop(test) end)
  end

  defp receive_loop(test) do
    receive do
      :stop ->
        :ok

      message ->
        send(test, {:phone, self(), message})
        receive_loop(test)
    end
  end

  test "with no phone, the seat holds its place for the configured time, then leaves" do
    %{seat: seat} = start_seat(hold_ms: 200)
    ref = Process.monitor(seat)
    assert_receive :upstream_closed, 500
    assert_receive {:DOWN, ^ref, _, _, :normal}
  end

  test "a phone returning within the hold keeps the seat" do
    %{seat: seat} = start_seat(hold_ms: 300)
    p = phone()
    :ok = Seat.attach(seat, p)
    assert_receive {:phone, ^p, {:seat_state, _}}

    send(p, :stop)
    Process.sleep(50)
    q = phone()
    :ok = Seat.attach(seat, q)
    assert_receive {:phone, ^q, {:seat_state, _}}
    # Past when the hold would have run out.
    refute_receive :upstream_closed, 400
  end

  test "the hold starts again when the last phone goes" do
    # Long enough that the phone attaches before a first hold could run out.
    %{seat: seat} = start_seat(hold_ms: 300)
    p = phone()
    :ok = Seat.attach(seat, p)
    refute_receive :upstream_closed, 400
    send(p, :stop)
    assert_receive :upstream_closed, 1000
  end

  test "answers for an absent phone when the question's time runs out" do
    clock = start_supervised!({Agent, fn -> 1_000 end})
    %{seat: seat} = start_seat(now: fn -> Agent.get(clock, & &1) end)
    lobby(seat)
    sporcle(seat, "game_question", %{"questionIndex" => 0, "question" => "?"})
    :sys.get_state(seat)

    Agent.update(clock, &(&1 + 15_000))
    send(seat, :deadline)
    assert_receive {:sent, "answer_question", %{questionIndex: 0, wagerAmount: 1, guessText: ""}}
  end

  test "lets the host reveal without everyone a while after the time runs out" do
    clock = start_supervised!({Agent, fn -> 1_000 end})
    %{seat: seat} = start_seat(now: fn -> Agent.get(clock, & &1) end)
    lobby(seat)
    sporcle(seat, "game_question", %{"questionIndex" => 0, "question" => "?"})
    refute :sys.get_state(seat).state.overtime

    Agent.update(clock, &(&1 + 15_000 + State.reveal_grace_ms()))
    send(seat, :deadline)
    Process.sleep(20)
    assert :sys.get_state(seat).state.overtime
  end

  test "a phone that attaches mid-question gets everything it missed" do
    %{seat: seat} = start_seat()
    lobby(seat)
    sporcle(seat, "game_question", %{"questionIndex" => 0, "question" => "🇮🇳"})

    p = phone()
    :ok = Seat.attach(seat, p)

    assert_receive {:phone, ^p,
                    {:seat_state, %{phase: :question, question: %{text: "🇮🇳"}, players: [_, _]}}}
  end

  describe "how long a seat lives" do
    test "a seat no phone ever attached to is held only briefly" do
      %{seat: seat} = start_seat(attach_ms: 200, hold_ms: 60_000)
      ref = Process.monitor(seat)
      assert_receive :upstream_closed, 1000
      assert_receive {:DOWN, ^ref, _, _, :normal}
    end

    test "once a phone has come, the whole hold applies" do
      %{seat: seat} = start_seat(attach_ms: 50, hold_ms: 400)
      p = phone()
      :ok = Seat.attach(seat, p)
      send(p, :stop)
      refute_receive :upstream_closed, 200
      assert_receive :upstream_closed, 1000
    end

    test "ends at its maximum age, even with a phone attached" do
      %{seat: seat} = start_seat(max_ms: 100)
      p = phone()
      :ok = Seat.attach(seat, p)
      assert_receive {:phone, ^p, {:seat_closed, %{reason: "expired"}}}, 1000
      assert_receive :upstream_closed
    end
  end

  describe "one seat per player" do
    test "a new seat for the same player ends the old one, and says why" do
      old = start_seat()
      p = phone()
      :ok = Seat.attach(old.seat, p)
      ref = Process.monitor(old.seat)

      new = start_seat(me: old.me)
      assert_receive {:phone, ^p, {:seat_closed, %{reason: "left", replaced: true}}}
      assert_receive {:DOWN, ^ref, _, _, :normal}
      assert Process.alive?(new.seat)
      assert TriviaRelay.Seats.whereis(new.id) == new.seat
    end

    test "the new seat keeps what the old one spent in the same game" do
      old = start_seat()
      lobby(old.seat)
      sporcle(old.seat, "game_question", %{"questionIndex" => 0, "question" => "?"})
      :ok = Seat.intent(old.seat, "answer", %{"text" => "x", "wager" => 5})

      new = start_seat(me: old.me)
      lobby(new.seat)
      sporcle(new.seat, "game_question", %{"questionIndex" => 1, "question" => "?"})
      state = :sys.get_state(new.seat).state
      assert State.wager_choices(state) == [1, 2, 3, 4]
      assert State.answered?(state, 0)
    end

    test "a seat in another game starts afresh" do
      old = start_seat()
      lobby(old.seat)
      sporcle(old.seat, "game_question", %{"questionIndex" => 0, "question" => "?"})
      :ok = Seat.intent(old.seat, "answer", %{"text" => "x", "wager" => 5})

      new = start_seat(me: old.me, game_code: "111222")
      lobby(new.seat)
      sporcle(new.seat, "game_question", %{"questionIndex" => 1, "question" => "?"})
      assert State.wager_choices(:sys.get_state(new.seat).state) == [1, 2, 3, 4, 5]
    end
  end

  test "the oldest phone makes way past the seat's limit" do
    %{seat: seat} = start_seat(max_phones: 2)
    [p, q, r] = for _ <- 1..3, do: phone()

    for phone <- [p, q, r] do
      :ok = Seat.attach(seat, phone)
      assert_receive {:phone, ^phone, {:seat_state, _}}
    end

    assert_receive {:phone, ^p, :seat_detached}
    assert :sys.get_state(seat).conns |> Map.keys() |> Enum.sort() == Enum.sort([q, r])

    # The one pushed out going away doesn't start the hold.
    send(p, :stop)
    lobby(seat)
    assert_receive {:phone, ^q, {:seat_state, %{status: :live}}}
    refute_received {:phone, ^p, _}
  end

  test "malformed Sporcle events are ignored, and the seat carries on" do
    %{seat: seat} = start_seat()
    p = phone()
    :ok = Seat.attach(seat, p)
    lobby(seat)
    sporcle(seat, "game_question", %{"questionIndex" => 0, "question" => "?"})
    before = :sys.get_state(seat).state

    for {event, payload} <- [
          {"judgement_update", %{"playerJudgements" => [1, 2]}},
          {"list_answers", %{"questionIndex" => 0, "allPlayerAnswers" => "x"}},
          {"list_answers", %{"questionIndex" => "0", "allPlayerAnswers" => []}},
          {"list_final_wagers", %{"allPlayerFinalWagers" => [1, nil, %{"peerId" => "x"}]}},
          {"list_final_wagers", %{"allPlayerFinalWagers" => %{}}},
          {"game_info", %{"gameOptions" => %{"QUESTIONS_PER_GAME" => "5"}}},
          {"game_info", %{"gameOptions" => %{"QUESTIONS_PER_GAME" => 1_000_000_000}}},
          {"game_info", %{"gameOptions" => %{"QUESTION_SECONDS" => 1_000_000_000_000}}},
          {"game_info", [1, 2]},
          {"game_connect", "lobby"},
          {"game_question", %{"questionIndex" => 1.5, "question" => "?"}},
          {"vote_final_round", %{"finalVotes" => [1]}},
          {"advance_all", %{"currentView" => 3}},
          {"player_update", %{"player" => [1]}},
          {"player_update", %{"player" => %{"peerId" => "3"}}}
        ] do
      sporcle(seat, event, payload)
    end

    after_ = :sys.get_state(seat).state
    assert after_.questions_per_game == 5 and after_.question_seconds == 15
    assert Map.keys(after_.players) == [1, 2]
    assert after_.phase == before.phase and after_.question == before.question
    assert after_.answers == before.answers

    sporcle(seat, "game_question", %{"questionIndex" => 1, "question" => "next"})
    assert_receive {:phone, ^p, {:seat_state, %{question: %{index: 1, text: "next"}}}}
  end

  test "status reports and crash reports keep the players out" do
    %{seat: seat} =
      start_seat(player: %{"deviceId" => "device-secret", "sporcleHandle" => "Me"})

    lobby(seat)

    sporcle(seat, "list_answers", %{
      "questionIndex" => 0,
      "answer" => "the-answer",
      "allPlayerAnswers" => [%{"peerId" => 1, "guessText" => "a-guess"}]
    })

    status = inspect(:sys.get_status(seat), limit: :infinity, printable_limit: :infinity)
    assert status =~ "624949"

    for secret <- ~w(device-secret psess-x hostPlayer the-answer a-guess P1) do
      refute status =~ secret
    end
  end
end
