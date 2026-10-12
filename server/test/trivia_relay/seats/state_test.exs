defmodule TriviaRelay.Seats.StateTest do
  use ExUnit.Case, async: true

  alias TriviaRelay.Fixtures
  alias TriviaRelay.Seats.{State, View}

  # A real game, as its host's connection received it (protocol/fixtures/sporcle/).
  setup_all do
    %{"me" => me, "events" => events} = Fixtures.read!("sporcle/hosted_game.json")
    %{me: me, events: events}
  end

  defp replay(me, events) do
    Enum.scan(events, {State.new(me), nil}, fn e, {s, _} ->
      {State.apply_event(s, e["event"], e["payload"], e["t_ms"]), e}
    end)
  end

  test "walks the phases of a whole game, final round included", %{me: me, events: events} do
    phases =
      replay(me, events)
      |> Enum.map(fn {s, _} -> s.phase end)
      |> Enum.dedup()

    # The host restarted the final once by mistake: vote, wager, vote again.
    assert phases == [
             :lobby,
             :question,
             :reveal,
             :question,
             :reveal,
             :question,
             :reveal,
             :question,
             :reveal,
             :question,
             :reveal,
             :final_vote,
             :final_wager,
             :final_vote,
             :final_wager,
             :final_question,
             :final_reveal,
             :final_scores,
             :lobby
           ]
  end

  test "the final's settled marks end the game, with no word from the host", %{
    me: me,
    events: events
  } do
    {s, _} = replay(me, events) |> Enum.find(fn {s, _} -> s.phase == :final_reveal end)
    s = State.apply_event(s, "judged_answers", nil, 0)
    assert s.phase == :final_scores
    assert s.judged
  end

  test "knows who it is, and that it hosts", %{me: me, events: events} do
    {s, _} = replay(me, events) |> Enum.at(2)
    assert s.peer_id == 1
    assert State.host?(s)
    assert s.questions_per_game == 5 and s.question_seconds == 15
  end

  test "ends with the judged final scores", %{me: me, events: events} do
    {s, _} =
      replay(me, events)
      |> Enum.find(fn {s, _} -> s.phase == :final_scores end)

    assert %{1 => %{score: -20}, 2 => %{score: 11}} = s.players
    assert s.final.picked == "easy"
    assert s.final.wagers == %{1 => 20, 2 => 10}
  end

  test "times a question from its arrival, the first after the start's countdown", %{
    me: me,
    events: events
  } do
    {s, e} = replay(me, events) |> Enum.find(fn {s, _} -> s.phase == :question end)
    assert s.countdown == %{kind: "start", until: e["t_ms"] + 5_000}
    assert s.deadline == e["t_ms"] + 5_000 + 15_000
    assert s.question.index == 0 and s.question.final == false

    {s, e} =
      replay(me, events)
      |> Enum.find(fn {s, _} -> s.phase == :question and s.question.index == 1 end)

    assert s.countdown == nil
    assert s.deadline == e["t_ms"] + 15_000

    {s, e} = replay(me, events) |> Enum.find(fn {s, _} -> s.phase == :final_question end)
    assert s.countdown == %{kind: "final", until: e["t_ms"] + 3_000}
    assert s.deadline == e["t_ms"] + 3_000 + 15_000
  end

  test "shows others' guesses once you've answered, and the answer only at the reveal",
       %{me: me, events: events} do
    states = replay(me, events)

    # Both players have answered question 0; the host hasn't revealed yet.
    {open, _} =
      Enum.find(states, fn {s, _} ->
        s.phase == :question and map_size(get_in(s.answers, [0, :entries]) || %{}) == 2
      end)

    view = View.snapshot(open, "624949", 0)
    assert view.reveal == nil
    assert Enum.all?(view.players, & &1.answered)
    assert Enum.map(view.players, & &1.guess) == ["nope", "germany"]
    assert view.you.answer == %{text: "nope", wager: 2}

    # The same moment for a host who hasn't answered yet: no guesses.
    unanswered = update_in(open.answers[0].entries, &Map.delete(&1, open.peer_id))
    view = View.snapshot(unanswered, "624949", 0)
    assert Enum.map(view.players, & &1.guess) == [nil, nil]
    assert view.you.answer == nil

    {revealed, _} = Enum.find(states, fn {s, _} -> s.phase == :reveal end)
    view = View.snapshot(revealed, "624949", 0)
    assert view.reveal.answer == "الهند"
    assert [%{peer_id: 1, text: "nope"}, %{peer_id: 2, text: "germany"}] = view.reveal.answers
    assert Enum.all?(view.players, &(not &1.answered and &1.guess == nil))
  end

  test "spends each regular wager once", %{me: me, events: events} do
    {s, _} = replay(me, events) |> Enum.find(fn {s, _} -> s.phase == :final_vote end)
    # The host wagered 2, 3, 4, 5, 1 across the five questions.
    assert State.wager_choices(s) == []

    {s, _} =
      replay(me, events)
      |> Enum.find(fn {s, _} -> s.phase == :question and s.question.index == 2 end)

    # By question 2 it has spent 2 and 3.
    assert State.wager_choices(s) == [1, 4, 5]
  end

  describe "due/2" do
    setup %{me: me, events: events} do
      {s, e} = replay(me, events) |> Enum.find(fn {s, _} -> s.phase == :question end)
      %{s: %{s | answers: %{}}, deadline: e["t_ms"] + 5_000 + 15_000}
    end

    test "answers for an absent player when time runs out", %{s: s, deadline: deadline} do
      assert State.due(s, deadline - 1) == []
      assert State.due(s, deadline) == [{:answer, 0, "", 1}]

      s = State.draft(s, "india", 3)
      assert State.due(s, deadline) == [{:answer, 0, "india", 3}]
    end

    test "does nothing once the player has answered", %{s: s, deadline: deadline} do
      s = State.sent(s, 0, "india", 4)
      assert State.due(s, deadline) == []
    end
  end

  describe "what Sporcle sends is checked before it is kept" do
    # Any player can put any JSON through Sporcle, so none of it is trusted.
    setup %{me: me, events: events} do
      {s, _} = replay(me, events) |> Enum.find(fn {s, _} -> s.phase == :question end)
      %{s: s}
    end

    test "malformed events change nothing", %{s: s} do
      for {event, payload} <- [
            {"game_info", "x"},
            {"game_info", %{"allPlayers" => "x", "gamePack" => "x", "gameOptions" => 5}},
            {"game_connect", [1]},
            {"player_connect", %{"player" => %{"peerId" => [1]}}},
            {"game_question", %{"questionIndex" => -1, "question" => "?"}},
            {"game_question", %{"questionIndex" => 10_000, "question" => "?"}},
            {"list_answers", %{"questionIndex" => 0, "allPlayerAnswers" => %{"a" => 1}}},
            {"list_answers", %{"questionIndex" => 1.0}},
            {"judgement_update", %{"playerJudgements" => "x"}},
            {"vote_final_round", %{"finalVotes" => nil}},
            {"list_final_wagers", %{"allPlayerFinalWagers" => "x"}},
            {"advance_all", %{"currentView" => %{}}},
            {"change_pack", %{"gamePack" => %{"id" => [1], "name" => "x"}}},
            {"change_pack", %{"gamePack" => %{"id" => 1, "name" => nil}}}
          ] do
        assert State.apply_event(s, event, payload, 0) |> Map.put(:status, s.status) == s,
               "#{event} #{inspect(payload)}"
      end
    end

    test "game options are only the ones the game offers", %{s: s} do
      for bad <- ["10", 1_000_000_000, 0, 7, nil, [10]] do
        s =
          State.apply_event(
            s,
            "game_info",
            %{"gameOptions" => %{"QUESTIONS_PER_GAME" => bad, "QUESTION_SECONDS" => bad}},
            0
          )

        assert {s.questions_per_game, s.question_seconds} == {5, 15}
      end

      s =
        State.apply_event(
          s,
          "game_info",
          %{"gameOptions" => %{"QUESTIONS_PER_GAME" => 20, "QUESTION_SECONDS" => 60}},
          0
        )

      assert {s.questions_per_game, s.question_seconds} == {20, 60}
    end

    test "keeps the parts that fit and drops the rest", %{s: s} do
      long = String.duplicate("é", 5_000)

      s =
        State.apply_event(
          s,
          "list_answers",
          %{
            "questionIndex" => 0,
            "answer" => long,
            "allPlayerAnswers" => [
              %{"peerId" => 1, "guessText" => long, "wagerAmount" => "3", "score" => 1.5},
              %{"peerId" => "2", "guessText" => "x"},
              "junk",
              nil
            ]
          },
          0
        )

      assert %{1 => %{text: text, wager: nil, score: nil}} = s.answers[0].entries
      assert map_size(s.answers[0].entries) == 1
      assert String.length(text) == 200
      assert String.length(s.answers[0].answer) == 2_000
      assert State.own_answer(s, 0) == %{text: text, wager: 0}

      s =
        State.apply_event(
          s,
          "judgement_update",
          %{"playerJudgements" => %{"2" => true, "77" => true, "x" => true}},
          0
        )

      assert s.judgements == %{2 => true}

      s =
        State.apply_event(
          s,
          "vote_final_round",
          %{"finalVotes" => %{"easy" => 1, "evil" => 2, "hard" => "3"}},
          0
        )

      assert s.final.votes == %{"easy" => 1}

      s =
        State.apply_event(
          s,
          "list_final_wagers",
          %{
            "allPlayerFinalWagers" => [%{"peerId" => 2, "finalWager" => 10}, %{"peerId" => 1}, 3]
          },
          0
        )

      assert s.final.wagers == %{2 => 10}
    end

    test "names are bounded, and every player has one", %{s: s} do
      s =
        State.apply_event(
          s,
          "player_connect",
          %{
            "player" => %{"peerId" => 3, "teamName" => String.duplicate("n", 500), "score" => "9"}
          },
          0
        )
        |> State.apply_event(
          "player_connect",
          %{"player" => %{"peerId" => 4, "teamName" => 4}},
          0
        )

      assert String.length(s.players[3].name) == 64
      assert s.players[3].score == 0
      assert s.players[4].name == "Player 4"
    end

    test "the players are bounded, but never without this seat's own", %{s: s} do
      crowd = for peer <- 10..1_000, do: %{"peerId" => peer, "teamName" => "x"}
      me = %{"peerId" => 5_000, "playerId" => s.me, "teamName" => "me"}
      s = State.apply_event(s, "game_info", %{"allPlayers" => crowd ++ [me]}, 0)

      assert map_size(s.players) == 101
      assert s.peer_id == 5_000

      s = State.apply_event(s, "player_connect", %{"player" => %{"peerId" => 9_999}}, 0)
      refute Map.has_key?(s.players, 9_999)
    end

    test "numbers the app can't hold are dropped", %{s: s} do
      s = State.apply_event(s, "player_connect", %{"player" => %{"peerId" => 2 ** 60}}, 0)
      refute Map.has_key?(s.players, 2 ** 60)
    end
  end

  test "a round plan keeps only proper entries", %{me: me} do
    rounds = [%{"questionIndex" => 0, "percent" => "90"}, 1, "x", %{"questionIndex" => "1"}]
    s = State.apply_event(State.new(me), "game_info", %{"allRounds" => rounds}, 0)
    assert s.rounds == [%{index: 0, percent: 90}]
  end

  test "a new seat takes over what the player's earlier one spent", %{me: me, events: events} do
    {old, _} =
      replay(me, events)
      |> Enum.find(fn {s, _} -> s.phase == :question and s.question.index == 2 end)

    s = State.carry_over(State.new(me), old)
    assert Map.keys(s.sent) == [0, 1]
    s = %{s | questions_per_game: 5}
    assert State.wager_choices(s) == [1, 4, 5]
  end

  describe "final wagers" do
    setup %{me: me, events: events} do
      {s, _} =
        replay(me, events)
        |> Enum.find(fn {s, _} -> s.phase == :final_wager and map_size(s.final.wagers) == 1 end)

      %{s: s}
    end

    test "hide the others' amounts while wagering", %{s: s} do
      # Only the joiner (peer 2) has wagered; the host (peer 1) is this seat.
      view = View.snapshot(s, "624949", 0)
      assert view.final.wagers == []
      assert view.final.wager == nil
      assert Enum.find(view.players, &(&1.peer_id == 2)).final_wagered

      joiner = %{s | peer_id: 2}
      view = View.snapshot(joiner, "624949", 0)
      assert view.final.wagers == [%{peer_id: 2, wager: 10}]
      assert view.final.wager == 10
    end

    test "show them once the question is asked", %{s: s} do
      s = State.apply_event(s, "game_question", %{"questionIndex" => 5, "question" => "?"}, 0)
      assert View.snapshot(s, "624949", 0).final.wagers == [%{peer_id: 2, wager: 10}]
    end
  end
end
