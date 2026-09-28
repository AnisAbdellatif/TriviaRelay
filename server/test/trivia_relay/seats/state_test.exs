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

  test "times a question from its arrival", %{me: me, events: events} do
    {s, e} = replay(me, events) |> Enum.find(fn {s, _} -> s.phase == :question end)
    assert s.deadline == e["t_ms"] + 15_000
    assert s.question.index == 0 and s.question.final == false
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
      %{s: %{s | answers: %{}}, deadline: e["t_ms"] + 15_000}
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
end
