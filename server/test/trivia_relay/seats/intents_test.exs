defmodule TriviaRelay.Seats.IntentsTest do
  use ExUnit.Case, async: true

  alias TriviaRelay.Replay
  alias TriviaRelay.Seats.{Intents, State}

  describe "answering" do
    test "sends the answer with its wager, once" do
      s = Replay.fresh(:question)

      assert {:ok, [{"answer_question", %{questionIndex: 0, wagerAmount: 3, guessText: "india"}}],
              s} = Intents.handle(s, "answer", %{"text" => "india", "wager" => 3})

      assert {:error, "already_answered"} =
               Intents.handle(s, "answer", %{"text" => "x", "wager" => 4})

      assert State.wager_choices(s) == [1, 2, 4, 5]
    end

    test "refuses a wager already spent this game, which Sporcle itself would take" do
      s =
        Replay.first(&(&1.phase == :question and &1.question.index == 2 and &1.answers[2] == nil))

      assert {:error, "invalid_wager"} =
               Intents.handle(s, "answer", %{"text" => "x", "wager" => 2})

      assert {:error, "invalid_wager"} =
               Intents.handle(s, "answer", %{"text" => "x", "wager" => 0})
    end

    test "the final answer carries the final wager, whatever the phone sends" do
      s = Replay.fresh(:final_question) |> Map.put(:sent, %{}) |> State.wagered(20)
      s = %{s | answers: Map.delete(s.answers, 5)}

      assert {:ok, [{"answer_question", %{questionIndex: 5, wagerAmount: 20}}], _} =
               Intents.handle(s, "answer", %{"text" => "denmark", "wager" => 1})
    end

    test "is refused outside a question" do
      assert {:error, "wrong_phase"} =
               Intents.handle(Replay.fresh(:reveal), "answer", %{"text" => "x", "wager" => 1})
    end
  end

  describe "the final round" do
    test "votes once" do
      s = Replay.fresh(:final_vote) |> put_in([Access.key(:final), :vote], nil)

      assert {:ok, [{"vote_final_round", %{voteType: "hard"}}], s} =
               Intents.handle(s, "final_vote", %{"choice" => "hard"})

      assert {:error, "already_voted"} = Intents.handle(s, "final_vote", %{"choice" => "easy"})
    end

    test "wagers 0, 10 or 20, once" do
      s = Replay.fresh(:final_wager)
      assert {:error, "invalid_wager"} = Intents.handle(s, "final_wager", %{"amount" => 15})

      assert {:ok, [{"submit_final_wager", %{wagerAmount: 10}}], s} =
               Intents.handle(s, "final_wager", %{"amount" => 10})

      assert {:error, "already_wagered"} = Intents.handle(s, "final_wager", %{"amount" => 20})
    end
  end

  describe "hosting" do
    test "moves the game along the way the official app does" do
      assert {:ok, [{"start_game", :none}], _} =
               Intents.handle(Replay.fresh(:lobby), "start", %{})

      assert {:ok, [{"advance_all", %{currentView: "GameShowAnswer"}}], _} =
               Intents.handle(all_answered(:question), "reveal", %{})

      assert {:ok, [{"next_question", %{questionIndex: 0, toFinalRound: false}}], _} =
               Intents.handle(Replay.fresh(:reveal), "next", %{})

      last = Replay.first(&(&1.phase == :reveal and &1.question.index == 4))

      assert {:ok, [{"next_question", %{questionIndex: 4, toFinalRound: true}}], _} =
               Intents.handle(last, "next", %{})

      assert {:ok, [{"advance_all", %{currentView: "voteCategory"}}], _} =
               Intents.handle(Replay.fresh(:final_vote), "next", %{})

      # The question before the final, and no toFinalRound: that would restart the final.
      assert {:ok, [{"next_question", payload}], _} =
               Intents.handle(Replay.fresh(:final_wager), "next", %{})

      assert payload == %{questionIndex: 4}

      assert {:ok, [{"advance_all", %{currentView: "showAnswer"}}], _} =
               Intents.handle(all_answered(:final_question), "reveal", %{})

      assert {:ok, [{"advance_all", %{currentView: "score"}}], _} =
               Intents.handle(Replay.fresh(:final_reveal), "next", %{})

      assert {:ok, [{"play_again", :none}], _} =
               Intents.handle(Replay.fresh(:final_scores), "play_again", %{})
    end

    test "judges with the whole map on every tap, then submits it" do
      s = Replay.fresh(:reveal)

      assert {:ok, [{"judgement_update", %{questionIndex: 0, playerJudgements: %{"2" => true}}}],
              s} =
               Intents.handle(s, "judge", %{"peer_id" => 2, "correct" => true})

      assert {:ok, [{"judgement_update", %{playerJudgements: %{"1" => false, "2" => true}}}], s} =
               Intents.handle(s, "judge", %{"peer_id" => 1, "correct" => false})

      assert {:ok,
              [
                {"judge_answers",
                 %{questionIndex: 0, playerJudgements: %{"1" => false, "2" => true}}}
              ], _} =
               Intents.handle(s, "judge_submit", %{})
    end

    test "edits options in the lobby, from the values the app offers" do
      s = Replay.fresh(:lobby)
      options = %{"questions_per_game" => 10, "question_seconds" => 30, "audience" => "private"}

      assert {:ok,
              [
                {"edit_options",
                 %{
                   "QUESTIONS_PER_GAME" => 10,
                   "QUESTION_SECONDS" => 30,
                   "AUDIENCE_TYPE" => "private"
                 }}
              ], _} =
               Intents.handle(s, "options", options)

      assert {:error, "invalid_options"} =
               Intents.handle(s, "options", %{options | "question_seconds" => 20})
    end

    test "is the host's alone" do
      s = Replay.fresh(:question, :join)
      refute State.host?(s)
      assert {:error, "not_host"} = Intents.handle(s, "reveal", %{})
    end
  end

  describe "changing the pack" do
    test "is the host's, in the lobby, and shows at once" do
      pack = %{"id" => 268_682, "name" => "Capitals"}

      assert {:ok, [{"change_pack", %{gamePack: ^pack}}], s} =
               Intents.change_pack(Replay.fresh(:lobby), pack)

      assert s.pack.id == 268_682

      assert {:error, "not_host"} = Intents.change_pack(Replay.fresh(:lobby, :join), pack)
      assert {:error, "wrong_phase"} = Intents.change_pack(Replay.fresh(:question), pack)
    end
  end

  test "anybody may ask to play again, once" do
    s = Replay.fresh(:final_scores, :join)
    refute State.host?(s)
    assert {:ok, [{"play_again", :none}], s} = Intents.handle(s, "play_again", %{})
    assert s.played_again
    assert {:ok, [], _} = Intents.handle(s, "play_again", %{})
    assert {:error, "wrong_phase"} = Intents.handle(Replay.fresh(:lobby), "play_again", %{})
  end

  test "the final vote is easy, medium or hard" do
    s = Replay.fresh(:final_vote) |> put_in([Access.key(:final), :vote], nil)

    for choice <- ~w(easy medium hard),
        do:
          assert(
            {:ok, [{"vote_final_round", %{voteType: ^choice}}], _} =
              Intents.handle(s, "final_vote", %{"choice" => choice})
          )

    assert {:error, "wrong_phase"} = Intents.handle(s, "final_vote", %{"choice" => "extreme"})
  end

  describe "revealing" do
    test "waits for everyone's answer, as the official app does" do
      s = Replay.fresh(:question)
      assert {:error, "not_everyone_answered"} = Intents.handle(s, "reveal", %{})
      refute State.can_reveal?(s)
      assert State.can_reveal?(all_answered(:question))
    end

    test "is allowed without everyone once time has been up for a while" do
      s = Replay.fresh(:question)
      assert {:ok, [{"advance_all", _}], _} = Intents.handle(State.overtime(s, 0), "reveal", %{})
      refute State.can_reveal?(State.overtime(s, 1)), "overtime is for the open question only"
    end

    test "doesn't wait for a player who is spectating or gone" do
      s = Replay.first(&(&1.phase == :question and answered_by(&1) == [1]))
      refute State.can_reveal?(s)

      assert State.can_reveal?(put_in(s.players[2].spectate, true))
      assert State.can_reveal?(put_in(s.players[2].connected, false))
    end
  end

  test "marks the seat ready itself, since Sporcle doesn't echo it back" do
    s = Replay.fresh(:lobby)

    assert {:ok, [{"player_update", %{readyForGame: false}}], s} =
             Intents.handle(s, "ready", %{"ready" => false})

    refute s.players[s.peer_id].ready

    assert {:ok, [{"player_update", %{readyForGame: true}}], s} =
             Intents.handle(s, "ready", %{"ready" => true})

    assert s.players[s.peer_id].ready
  end

  test "nothing goes to Sporcle before the seat is connected" do
    assert {:error, "not_live"} =
             Intents.handle(State.new("sporcle_id//x"), "ready", %{"ready" => true})
  end

  defp all_answered(phase),
    do: Replay.first(&(&1.phase == phase and length(answered_by(&1)) == 2))

  defp answered_by(s), do: Map.keys(get_in(s.answers, [s.question.index, :entries]) || %{})
end
