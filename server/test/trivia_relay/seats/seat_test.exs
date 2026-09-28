defmodule TriviaRelay.Seats.SeatTest do
  use TriviaRelayWeb.ChannelCase, async: true

  alias TriviaRelay.Seats.{Seat, State}

  defp phone do
    test = self()
    spawn(fn -> receive_loop(test) end)
  end

  defp receive_loop(test) do
    receive do
      :stop -> :ok
      message -> send(test, {:phone, self(), message}) && receive_loop(test)
    end
  end

  test "with no phone, the seat holds its place for the configured time, then leaves" do
    %{seat: seat} = start_seat(hold_ms: 50)
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
end
