defmodule TriviaRelay.Seats.GameFlowTest do
  @moduledoc """
  The host's player menu, going back to the lobby, hosting as a spectator, joining a game
  under way, the start's countdown, pack votes, rating and reporting questions, notices and
  the next game's code: each as the official app does it (protocol/SPORCLE.md).
  """

  use ExUnit.Case, async: true

  alias TriviaRelay.Seats.{Intents, State, View}

  @me "sporcle_id//me"
  @now 1_000_000

  defp player(peer, id, opts \\ []) do
    %{
      "peerId" => peer,
      "playerId" => id,
      "teamName" => "P#{peer}",
      "isHost" => Keyword.get(opts, :host, false),
      "spectate" => Keyword.get(opts, :spectate, false),
      "readyForGame" => Keyword.get(opts, :ready, true),
      "score" => 0
    }
  end

  # A lobby of five 15 s questions: this seat's player is peer 1 (the host unless `host:
  # false`), with peers 2 and 3.
  defp lobby(opts \\ []) do
    host? = Keyword.get(opts, :host, true)

    State.new(@me)
    |> State.apply_event(
      "game_info",
      %{
        "allPlayers" => [
          player(1, @me, host: host?, spectate: Keyword.get(opts, :spectate, false)),
          player(2, "sporcle_id//two", host: not host?),
          player(3, "sporcle_id//three")
        ],
        "gameOptions" => %{"QUESTIONS_PER_GAME" => 5, "QUESTION_SECONDS" => 15},
        "gamePack" => %{"id" => 1, "name" => "Flags"}
      },
      0
    )
    |> State.apply_event("game_connect", %{"inLobby" => true}, 0)
  end

  defp question(s, index, now \\ @now),
    do: State.apply_event(s, "game_question", %{"questionIndex" => index, "question" => "?"}, now)

  defp snapshot(s, now \\ @now), do: View.snapshot(s, "624949", now)

  describe "the host's player menu" do
    test "removes a player for now, or for good, as a bounce naming them" do
      s = lobby()

      assert {:ok, [{"bounce", %{peerId: 2, playerId: "sporcle_id//two", noReturn: false}}], _} =
               Intents.handle(s, "remove", %{"peer_id" => 2, "ban" => false})

      assert {:ok, [{"bounce", %{peerId: 3, noReturn: true}}], _} =
               Intents.handle(question(s, 0), "remove", %{"peer_id" => 3, "ban" => true})
    end

    test "hands the host to another player" do
      assert {:ok, [{"promote_new_host", %{peerId: 2}}], _} =
               Intents.handle(lobby(), "make_host", %{"peer_id" => 2})
    end

    test "is the host's, and never on themselves, nobody, or somebody who isn't there" do
      assert {:error, "not_host"} =
               Intents.handle(lobby(host: false), "remove", %{"peer_id" => 2, "ban" => true})

      assert {:error, "not_host"} =
               Intents.handle(lobby(host: false), "make_host", %{"peer_id" => 2})

      s = lobby()

      for payload <- [%{"peer_id" => 1}, %{"peer_id" => 99}, %{"peer_id" => "2"}] do
        assert {:error, "invalid_intent"} = Intents.handle(s, "make_host", payload)

        assert {:error, "invalid_intent"} =
                 Intents.handle(s, "remove", Map.put(payload, "ban", false))
      end

      gone = State.apply_event(s, "player_disconnect", %{"player" => player(2, "x")}, 0)

      assert {:error, "invalid_intent"} =
               Intents.handle(gone, "remove", %{"peer_id" => 2, "ban" => false})
    end

    test "a promotion says so to the new host" do
      s = State.apply_event(lobby(host: false), "promote_to_host", %{}, @now)
      assert State.host?(s)
      assert %{notice: %{kind: "promoted", until: until}} = snapshot(s)
      assert until == @now + 5_000

      s = State.apply_event(lobby(host: false), "promote_to_host", %{"oldHostLeft" => true}, @now)
      assert %{notice: %{kind: "host_left"}} = snapshot(s)
      assert %{notice: nil} = snapshot(s, @now + 5_000)
    end
  end

  describe "back to the lobby" do
    test "is the host's, from anywhere in a game" do
      s = question(lobby(), 0)
      assert {:ok, [{"go_to_lobby", :none}], _} = Intents.handle(s, "to_lobby", %{})
      assert {:error, "wrong_phase"} = Intents.handle(lobby(), "to_lobby", %{})

      assert {:error, "not_host"} =
               Intents.handle(question(lobby(host: false), 0), "to_lobby", %{})
    end

    test "tells everybody but the host, and starts the game afresh" do
      s = question(lobby(host: false), 0)
      {:ok, _, s} = Intents.handle(s, "answer", %{"text" => "x", "wager" => 5})

      s =
        State.apply_event(s, "go_to_lobby", %{"gamePack" => %{"id" => 2, "name" => "Caps"}}, @now)

      assert %{phase: :lobby, pack: %{id: 2}, notice: %{kind: "to_lobby"}} = snapshot(s)
      assert State.wager_choices(s) == [1, 2, 3, 4, 5]

      host = State.apply_event(question(lobby(), 0), "go_to_lobby", %{}, @now)
      assert %{phase: :lobby, notice: nil} = snapshot(host)
    end
  end

  describe "hosting as a spectator" do
    test "goes in the game options, and a lobby edit keeps it unless told" do
      assert {:ok, %{"SPECTATE" => true}} =
               Intents.validate_options(%{
                 "questions_per_game" => 5,
                 "question_seconds" => 15,
                 "audience" => "private",
                 "spectate" => true
               })

      assert {:ok, %{"SPECTATE" => false}} =
               Intents.validate_options(%{
                 "questions_per_game" => 5,
                 "question_seconds" => 15,
                 "audience" => "private"
               })

      assert {:error, "invalid_options"} =
               Intents.validate_options(%{
                 "questions_per_game" => 5,
                 "question_seconds" => 15,
                 "audience" => "private",
                 "spectate" => "yes"
               })

      options = %{"questions_per_game" => 10, "question_seconds" => 30, "audience" => "private"}

      assert {:ok, [{"edit_options", %{"SPECTATE" => true}}], _} =
               Intents.handle(lobby(spectate: true), "options", options)

      assert {:ok, [{"edit_options", %{"SPECTATE" => true}}], s} =
               Intents.handle(lobby(), "options", Map.put(options, "spectate", true))

      assert State.spectating?(s)
    end

    test "plays no part: no answer, vote or wager, and nothing answered for them" do
      s = question(lobby(spectate: true), 0)

      assert {:error, "spectating"} = Intents.handle(s, "answer", %{"text" => "x", "wager" => 5})
      assert {:error, "spectating"} = Intents.handle(s, "draft", %{"text" => "x", "wager" => 5})
      assert State.due(s, @now + 60_000) == []

      assert {:error, "spectating"} =
               Intents.handle(%{s | phase: :final_vote}, "final_vote", %{"choice" => "easy"})

      assert {:error, "spectating"} =
               Intents.handle(%{s | phase: :final_wager}, "final_wager", %{"amount" => 10})
    end

    test "still reveals, marks and moves on, and waits only for the players" do
      s = question(lobby(spectate: true), 0)
      refute State.can_reveal?(s)

      s =
        State.apply_event(
          s,
          "list_answers",
          %{
            "questionIndex" => 0,
            "answer" => "A",
            "allPlayerAnswers" => [
              %{"peerId" => 2, "guessText" => "a", "wagerAmount" => 1},
              %{"peerId" => 3, "guessText" => "b", "wagerAmount" => 2}
            ]
          },
          @now
        )

      assert State.can_reveal?(s)
      assert {:ok, [{"advance_all", _}], _} = Intents.handle(s, "reveal", %{})

      view = snapshot(s)
      assert view.you.spectating
      assert Enum.find(view.players, &(&1.peer_id == 1)).spectating

      assert Enum.all?(view.players, &(&1.guess == nil)),
             "a spectating host sees who answered, not what, until the reveal"

      revealed = State.apply_event(s, "advance_all", %{"currentView" => "GameShowAnswer"}, @now)

      assert {:ok, [{"judgement_update", _}], _} =
               Intents.handle(revealed, "judge", %{"peer_id" => 2, "correct" => true})
    end
  end

  describe "the start's countdown" do
    test "comes before the first question and the final one, on the relay's clock" do
      s = question(lobby(), 0)
      assert %{countdown: %{kind: "start", until: until}, deadline: deadline} = snapshot(s)
      assert until == @now + 5_000 and deadline == until + 15_000
      assert %{countdown: nil} = snapshot(s, until)

      assert %{countdown: nil, deadline: deadline} = snapshot(question(s, 1, @now + 30_000))
      assert deadline == @now + 30_000 + 15_000

      final = question(%{s | phase: :final_wager}, 5, @now + 90_000)

      assert %{countdown: %{kind: "final", until: until}, deadline: deadline} =
               snapshot(final, @now + 90_000)

      assert until == @now + 93_000 and deadline == until + 15_000
    end
  end

  describe "joining a game under way" do
    defp joined(connect, now \\ @now) do
      State.new(@me)
      |> State.apply_event(
        "game_info",
        %{
          "allPlayers" => [player(1, "sporcle_id//host", host: true), player(4, @me)],
          "gameOptions" => %{"QUESTIONS_PER_GAME" => 10, "QUESTION_SECONDS" => 45}
        },
        now
      )
      |> State.apply_event("game_connect", Map.merge(%{"inLobby" => false}, connect), now)
    end

    test "lands on the open question, with the time it has left and the wagers used" do
      s =
        joined(%{
          "currentView" => "GameAnswerQuestion",
          "questionIndex" => 2,
          "questionText" => "Capital of Chad?",
          "questionCategory" => "Capitals",
          "questionImgSrc" => "https://x/y.png",
          "timeElapsed" => 12,
          "usedWagers" => %{"3" => true, "7" => nil}
        })

      view = snapshot(s)
      assert view.phase == :question
      assert view.question.text == "Capital of Chad?" and view.question.index == 2
      assert view.question.category == "Capitals" and view.question.image_url == "https://x/y.png"
      assert view.deadline == @now + 45_000 - 12_000
      assert view.countdown == nil
      assert view.you.wager_choices == [1, 2, 4, 5, 6, 8, 9, 10]
      assert view.you.answer == nil
    end

    test "a rejoin keeps its answers: the current one is in, and each wager used once" do
      # As confirmed live: a rejoin during a reveal lists the player's own answers.
      s =
        joined(%{
          "currentView" => "GameAnswerWait",
          "questionIndex" => 1,
          "question" => "Q2",
          "questionText" => "Q2",
          "timeElapsed" => 35,
          "usedWagers" => %{"0" => false, "3" => false},
          "questions" => [
            %{"questionIndex" => 0, "guessText" => "test", "wagerAmount" => 0},
            %{"questionIndex" => 1, "guessText" => "wrong", "wagerAmount" => 3}
          ]
        })

      assert %{phase: :question, you: %{answer: %{text: "wrong", wager: 3}}} = snapshot(s)

      assert {:error, "already_answered"} =
               Intents.handle(s, "answer", %{"text" => "x", "wager" => 1})

      refute 3 in State.wager_choices(s)
      assert State.due(s, @now + 60_000) == []
    end

    test "places every view the official app knows" do
      regular = fn view ->
        joined(%{"currentView" => view, "questionIndex" => 0, "questionText" => "Q"})
      end

      final = fn view, extra ->
        joined(Map.merge(%{"currentView" => view, "questionIndex" => 10}, extra))
      end

      assert regular.("GameAnswerQuestion").phase == :question
      assert regular.("GameAnswerWait").phase == :question
      assert regular.("GameShowAnswer").phase == :reveal
      refute regular.("GameShowAnswer").judged
      assert %{phase: :reveal, judged: true} = regular.("MidRoundScores")
      assert regular.("SomethingNew").phase == :question

      assert %{phase: :final_vote, deadline: d} = final.("VOTE_CATEGORY", %{})
      assert d == @now + 15_000
      assert final.("voteCategory", %{}).phase == :final_vote

      assert %{phase: :final_wager, deadline: d, final: %{picked: "hard"}} =
               final.("CAST_WAGER", %{"pickedVote" => "hard", "timeElapsed" => 10})

      assert d == @now + 20_000
      assert final.("wait", %{}).phase == :final_wager

      assert %{phase: :final_question, question: %{final: true, text: "F"}, deadline: d} =
               final.("question", %{"questionText" => "F", "timeElapsed" => 5})

      assert d == @now + 40_000
      assert final.("answered", %{"questionText" => "F"}).phase == :final_question
      assert final.("showAnswer", %{}).phase == :final_reveal
      assert final.("FINAL_REVEAL", %{}).phase == :final_reveal
      assert final.("showAnswer", %{"judgeSubmitted" => true}).phase == :final_scores
      assert final.("score", %{}).phase == :final_scores
    end

    test "a first game_info that carries the round plan doesn't wipe a carried-over seat" do
      old = State.sent(State.new(@me), 0, "x", 5)

      s =
        State.new(@me)
        |> State.carry_over(old)
        |> State.apply_event("game_info", %{"allRounds" => [%{"questionIndex" => 0}]}, 0)

      assert State.answered?(s, 0)
      assert s.rounds == [%{index: 0, percent: nil}]

      # A later one starts a new game.
      s = State.apply_event(s, "game_info", %{"allRounds" => []}, 0)
      refute State.answered?(s, 0)
    end

    test "Sporcle's own list of used wagers counts, from list_answers and update_wagers" do
      s = question(lobby(host: false), 1)
      s = State.apply_event(s, "update_wagers", %{"wagers" => %{"2" => nil}}, 0)

      s =
        State.apply_event(
          s,
          "list_answers",
          %{"questionIndex" => 1, "allPlayerAnswers" => [], "playerWagers" => %{"4" => false}},
          0
        )

      assert State.wager_choices(s) == [1, 3, 5]

      assert {:error, "invalid_wager"} =
               Intents.handle(s, "answer", %{"text" => "x", "wager" => 4})
    end
  end

  describe "answers" do
    test "go trimmed and no longer than the official app's field" do
      s = question(lobby(), 0)
      long = "  " <> String.duplicate("a", 100) <> "  "

      assert {:ok, [{"answer_question", %{guessText: text}}], _} =
               Intents.handle(s, "answer", %{"text" => long, "wager" => 5})

      assert text == String.duplicate("a", 80)
    end
  end

  describe "pack votes" do
    defp votes(entries) do
      Map.new(entries, fn {id, voters} ->
        {"#{id}", %{"gamePack" => %{"id" => id, "name" => "Pack #{id}"}, "voters" => voters}}
      end)
    end

    test "are shown most voted first, with who voted" do
      s =
        State.apply_event(
          lobby(host: false),
          "pack_votes",
          %{"packVotes" => votes([{7, ["sporcle_id//two"]}, {8, [@me, "sporcle_id//three"]}])},
          0
        )

      assert [
               %{pack: %{id: 8}, votes: 2, voters: [1, 3], you: true},
               %{pack: %{id: 7}, votes: 1, voters: [2], you: false}
             ] = snapshot(s).pack_votes

      assert snapshot(question(s, 0)).pack_votes == []
    end

    test "a player votes for a pack already voted for, and takes it back" do
      s =
        State.apply_event(
          lobby(host: false),
          "pack_votes",
          %{"packVotes" => votes([{7, ["sporcle_id//two"]}])},
          0
        )

      assert {:ok, [{"vote_on_pack", %{gamePack: %{"id" => 7}} = payload}], s} =
               Intents.handle(s, "pack_vote", %{"pack_id" => 7, "vote" => true})

      refute Map.has_key?(payload, :unvote)
      assert [%{votes: 2, you: true}] = snapshot(s).pack_votes
      assert {:ok, [], ^s} = Intents.handle(s, "pack_vote", %{"pack_id" => 7, "vote" => true})

      assert {:ok, [{"vote_on_pack", %{gamePack: %{"id" => 7}, unvote: true}}], s} =
               Intents.handle(s, "pack_vote", %{"pack_id" => 7, "vote" => false})

      assert [%{votes: 1, you: false}] = snapshot(s).pack_votes

      assert {:error, "invalid_intent"} =
               Intents.handle(s, "pack_vote", %{"pack_id" => 99, "vote" => true})
    end

    test "a new pack comes whole from getPack; five a game at most, and never one's own draft" do
      pack = %{"id" => 20, "name" => "New"}

      assert {:ok, [{"vote_on_pack", %{gamePack: ^pack}}], s} =
               Intents.change_pack(lobby(host: false), pack)

      assert State.own_pack_votes(s) == [20]

      s =
        State.apply_event(
          lobby(host: false),
          "pack_votes",
          %{"packVotes" => votes(for id <- 1..5, do: {id, [@me]})},
          0
        )

      assert {:error, "too_many_votes"} = Intents.change_pack(s, pack)

      draft = %{
        "id" => 21,
        "name" => "Mine",
        "active" => false,
        "creator" => %{"playerId" => @me}
      }

      assert {:error, "draft_pack"} = Intents.change_pack(lobby(host: false), draft)
      assert {:error, "draft_pack"} = Intents.change_pack(lobby(), draft)
      assert {:error, "wrong_phase"} = Intents.change_pack(question(lobby(host: false), 0), pack)
    end

    test "carry over into the next game's lobby as Sporcle sends them" do
      s = question(lobby(), 0)

      s =
        State.apply_event(s, "next_game", %{"packVotes" => votes([{3, ["sporcle_id//two"]}])}, 0)

      assert [%{pack: %{id: 3}}] = snapshot(s).pack_votes
    end
  end

  describe "rating and reporting a question" do
    test "once answered and at the reveal, as the official app offers them" do
      s = question(lobby(), 0)
      assert {:error, "wrong_phase"} = Intents.handle(s, "rate", %{"rating" => 1})
      refute snapshot(s).you.can_rate

      {:ok, _, s} = Intents.handle(s, "answer", %{"text" => "x", "wager" => 5})
      assert snapshot(s).you.can_rate

      assert {:ok, [{"rate_question", %{questionIndex: 0, rating: 1}}], s} =
               Intents.handle(s, "rate", %{"rating" => 1})

      assert {:ok, [], ^s} = Intents.handle(s, "rate", %{"rating" => 1})

      assert {:ok, [{"rate_question", %{rating: -1}}], s} =
               Intents.handle(s, "rate", %{"rating" => -1})

      assert %{rating: -1, reported: false} = snapshot(s).you

      assert {:ok, [{"report_question", %{questionIndex: 0, reason: "typo"}}], s} =
               Intents.handle(s, "report", %{"reason" => "typo"})

      assert {:ok, [], _} = Intents.handle(s, "report", %{"reason" => "offensive"})
      assert snapshot(s).you.reported

      assert {:error, "invalid_intent"} = Intents.handle(s, "report", %{"reason" => "boring"})
      assert {:error, "invalid_intent"} = Intents.handle(s, "rate", %{"rating" => 5})

      revealed = State.apply_event(s, "advance_all", %{"currentView" => "GameShowAnswer"}, 0)

      assert {:ok, [{"rate_question", %{rating: 0}}], _} =
               Intents.handle(revealed, "rate", %{"rating" => 0})

      assert {:error, "wrong_phase"} = Intents.handle(lobby(), "report", %{"reason" => "typo"})
    end
  end

  describe "a message from Sporcle" do
    test "shows as a notice for its interval, within bounds" do
      s =
        State.apply_event(
          lobby(),
          "server_message",
          %{
            "type" => "warn",
            "title" => "Heads up",
            "message" => "Maintenance",
            "interval" => 8000
          },
          @now
        )

      assert %{
               notice: %{
                 kind: "server",
                 level: "warn",
                 title: "Heads up",
                 message: "Maintenance",
                 until: until
               }
             } = snapshot(s)

      assert until == @now + 8_000

      forever =
        State.apply_event(lobby(), "server_message", %{"message" => "Hi", "interval" => 0}, 0)

      assert %{level: "info", until: 60_000} = forever.notice

      unset = State.apply_event(lobby(), "server_message", %{"title" => "Hi", "type" => "bad"}, 0)
      assert %{level: "info", until: 5_000} = unset.notice

      long = String.duplicate("x", 5_000)

      huge =
        State.apply_event(
          lobby(),
          "server_message",
          %{"message" => long, "interval" => 1.0e12},
          0
        )

      assert String.length(huge.notice.message) == 2_000 and huge.notice.until == 60_000

      assert State.apply_event(lobby(), "server_message", %{"title" => " "}, 0).notice == nil
    end
  end

  describe "the next game" do
    test "leave_behind's code is kept on the final scores, for Play Again to join" do
      s = %{lobby() | phase: :final_scores}
      s = State.apply_event(s, "leave_behind", %{"gameCode" => "778899"}, 0)
      assert %{final: %{next_game_code: "778899"}} = snapshot(s)

      assert State.apply_event(s, "leave_behind", %{"gameCode" => "x"}, 0).next_game_code ==
               "778899"

      assert State.apply_event(lobby(), "leave_behind", %{"gameCode" => "1234"}, 0).next_game_code ==
               nil

      assert State.apply_event(s, "next_game", %{}, 0).next_game_code == nil
    end
  end

  describe "players" do
    test "carry whether they spectate and asked for the next game" do
      s =
        State.apply_event(
          lobby(),
          "player_update",
          %{"player" => Map.merge(player(2, "sporcle_id//two"), %{"readyForNextGame" => true})},
          0
        )

      assert %{ready_for_next_game: true, spectating: false} =
               Enum.find(snapshot(s).players, &(&1.peer_id == 2))
    end
  end
end
