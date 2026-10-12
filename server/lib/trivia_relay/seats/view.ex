defmodule TriviaRelay.Seats.View do
  @moduledoc """
  The snapshot a phone receives (`protocol/PROTOCOL.md` §5): the whole of what its seat
  knows, every time, never a delta.

  Sporcle sends `list_answers` with the correct answer and everybody's guesses on every
  submission, long before the reveal. The official app shows a player the others'
  guesses once they have answered themselves, and the correct answer only when the host
  reveals, and so does this. Final wagers are likewise hidden while wagering.
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
      final: final(s),
      notice: notice(s.notice, now),
      countdown: countdown(s.countdown, now),
      pack_votes: pack_votes(s),
      chat: chat(s),
      reactions: reactions(s, now)
    }
  end

  # The chat as the official app's MessageBoard shows it: the latest messages (the last
  # `window`, more as the phone asks), who else is typing, and how many came while it was
  # closed (the official app's red dot). A sender is shown by the name their message
  # carries, as there; `peer_id` is theirs while they are in the game.
  defp chat(s) do
    peers = Map.new(s.players, fn {peer, p} -> {p.player_id, peer} end)

    %{
      messages:
        for m <- State.chat_shown(s) do
          own? = m.player_id == s.me

          %{
            id: m.id,
            peer_id: peers[m.player_id],
            name: if(own?, do: get_in(s.players, [s.peer_id, :name]), else: nil) || m.name,
            text: m.text,
            image_url: m.image_url,
            system: m.system,
            at: m.at,
            own: own?
          }
        end,
      unread: s.chat.unread,
      typing:
        for({id, name} <- Enum.sort(s.chat.typing), id != s.me, do: name || "Someone")
        |> Enum.take(10),
      open: s.chat.open,
      has_more: State.chat_more?(s),
      loading: s.chat.loading
    }
  end

  # Reactions other players sent this one, for as long as they show: the app plays each
  # once and names who sent it.
  defp reactions(s, now) do
    for r <- s.reactions.received, r.until > now do
      %{id: r.id, peer_id: r.from, type: r.type, until: r.until}
    end
  end

  defp countdown(%{until: until} = countdown, now) when now < until, do: countdown
  defp countdown(_countdown, _now), do: nil

  # The lobby's pack votes, the most voted first (then by name), as the official app lists
  # them. Voters are shown by peer id; somebody who left still counts.
  defp pack_votes(%{phase: :lobby} = s) do
    peers = Map.new(s.players, fn {peer, p} -> {p.player_id, peer} end)

    s.pack_votes
    |> Map.values()
    |> Enum.sort_by(&{-length(&1.voters), &1.pack.name, &1.pack.id})
    |> Enum.map(fn %{pack: pack, voters: voters} ->
      %{
        pack: pack,
        votes: length(voters),
        voters: for(v <- voters, peer = peers[v], do: peer),
        you: s.me in voters
      }
    end)
  end

  defp pack_votes(_s), do: []

  # A notice is for a moment: gone from the snapshot once its time is up.
  defp notice(%{until: until} = notice, now) when now < until, do: notice
  defp notice(_notice, _now), do: nil

  defp players(s, index, open?) do
    # A spectator never answers, and sees only who has, until the reveal (as the official
    # app shows a spectating host "Answered").
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
        ready_for_next_game: p.ready_for_next_game,
        spectating: p.spectate,
        score: p.score,
        answered: open? and Map.has_key?(entries, p.peer_id),
        guess: if(guesses?, do: get_in(entries, [p.peer_id, :text])),
        final_wagered: s.phase == :final_wager and Map.has_key?(s.final.wagers, p.peer_id),
        reactions: Map.get(s.reactions.counts, p.player_id, %{total: 0, recent: []})
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
      played_again: s.played_again,
      spectating: State.spectating?(s),
      can_rate: State.rateable(s) != nil,
      rating: if(index, do: Map.get(s.ratings, index, 0), else: 0),
      reported: index != nil and Map.has_key?(s.reports, index),
      poppers: s.poppers
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
      next_game_code: s.next_game_code,
      votes: s.final.votes,
      picked: s.final.picked,
      vote: s.final.vote,
      wager: State.final_wager(s),
      wagers:
        s
        |> final_wagers(phase)
        |> Enum.sort()
        |> Enum.map(fn {p, w} -> %{peer_id: p, wager: w} end)
    }
  end

  defp final(_), do: nil

  # Sporcle sends every wager as it is placed. While the final is still being wagered, a
  # seat sees only its own amount (and who has wagered, `players[].final_wagered`), so
  # nobody can wager knowing the others'. Once the question is asked they are all fixed.
  defp final_wagers(s, phase) when phase in [:final_vote, :final_wager],
    do: Map.take(s.final.wagers, [s.peer_id])

  defp final_wagers(s, _phase), do: s.final.wagers

  defp stringify(map), do: Map.new(map, fn {k, v} -> {to_string(k), v} end)
end
