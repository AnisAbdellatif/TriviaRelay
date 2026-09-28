defmodule TriviaRelay.Seats.View do
  @moduledoc """
  The snapshot a phone receives (`protocol/PROTOCOL.md` §5): the whole of what its seat
  knows, every time, never a delta.

  Sporcle sends `list_answers` with the correct answer and everybody's guesses on every
  submission, long before the reveal. The official app shows a player the others'
  guesses once they have answered themselves, and the correct answer only when the host
  reveals, and so does this.
  """

  alias TriviaRelay.Protocol
  alias TriviaRelay.Seats.State

  @doc "The snapshot of `state` for the seat's phone at `now`."
  def snapshot(%State{} = s, game_code, now) do
    index = State.index(s)
    open? = State.open?(s)

    %{
      protocol_version: Protocol.major(),
      protocol_minor: Protocol.minor(),
      server_time: now,
      game_code: game_code,
      status: s.status,
      phase: s.phase,
      pack: s.pack,
      options: %{questions_per_game: s.questions_per_game, question_seconds: s.question_seconds},
      rounds: s.rounds,
      question: s.question,
      deadline: s.deadline,
      players: players(s, index, open?),
      you: you(s, index),
      reveal: if(index != nil and not open?, do: reveal(s, index)),
      final: final(s)
    }
  end

  defp players(s, index, open?) do
    guesses? = open? and State.answered?(s, index)
    entries = get_in(s.answers, [index, :entries]) || %{}

    s.players
    |> Map.values()
    |> Enum.sort_by(& &1.peer_id)
    |> Enum.map(fn p ->
      %{
        peer_id: p.peer_id,
        name: p.name,
        host: p.host,
        connected: p.connected,
        ready: p.ready,
        score: p.score,
        answered: open? and Map.has_key?(entries, p.peer_id),
        guess: if(guesses?, do: get_in(entries, [p.peer_id, :text])),
        final_wagered: s.phase == :final_wager and Map.has_key?(s.final.wagers, p.peer_id)
      }
    end)
  end

  defp you(s, index) do
    %{
      peer_id: s.peer_id,
      host: State.host?(s),
      can_reveal: State.host?(s) and State.can_reveal?(s),
      answer: index && State.own_answer(s, index),
      wager_choices:
        if(s.phase == :final_wager, do: State.final_wagers(), else: State.wager_choices(s)),
      judgements: if(State.host?(s), do: stringify(s.judgements), else: %{}),
      judged: s.judged,
      played_again: s.played_again
    }
  end

  defp reveal(s, index) do
    case s.answers[index] do
      nil ->
        nil

      %{answer: answer, entries: entries} ->
        %{
          answer: answer,
          answers:
            entries
            |> Enum.sort_by(fn {peer, _} -> peer end)
            |> Enum.map(fn {peer, e} ->
              %{peer_id: peer, text: e.text, wager: e.wager, correct: e.correct, score: e.score}
            end)
        }
    end
  end

  defp final(%{phase: phase} = s)
       when phase in [:final_vote, :final_wager, :final_question, :final_reveal, :final_scores] do
    %{
      votes: s.final.votes,
      picked: s.final.picked,
      vote: s.final.vote,
      wager: s.final.wager,
      wagers: s.final.wagers |> Enum.sort() |> Enum.map(fn {p, w} -> %{peer_id: p, wager: w} end)
    }
  end

  defp final(_), do: nil

  defp stringify(map), do: Map.new(map, fn {k, v} -> {to_string(k), v} end)
end
