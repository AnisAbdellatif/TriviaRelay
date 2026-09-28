defmodule TriviaRelay.Seats.State do
  @moduledoc """
  One seat's view of a Sporcle game, folded from the events its GameLift connection
  receives (`protocol/SPORCLE.md`). Pure: nothing here sends or reads the clock.

  Sporcle streams events and never repeats itself, so a phone that was away missed
  whatever was sent meanwhile. The relay keeps receiving on the phone's behalf and folds
  everything into this state, which `TriviaRelay.Seats.View` turns into one complete
  snapshot. Sporcle sends no deadlines either: each client times a question from the
  moment it arrives, so the relay does the same and records an absolute `deadline`.

  Phases:

    * `:lobby` — before the game, and again after `next_game`
    * `:question` — a regular question is open
    * `:reveal` — the host revealed it; the host judges, then moves on
    * `:final_vote` — everyone votes for an easy, medium or hard final question
    * `:final_wager` — everyone wagers 0, 10 or 20
    * `:final_question` — the final question is open
    * `:final_reveal` — the host revealed it and judges
    * `:final_scores` — the end of the game
  """

  @vote_ms 15_000
  @wager_ms 30_000
  @final_wagers [0, 10, 20]
  # How long after a question's time runs out the host may reveal it without everyone's
  # answer, as in the official app.
  @reveal_grace_ms 5_000

  defstruct me: nil,
            peer_id: nil,
            status: :connecting,
            phase: :lobby,
            pack: nil,
            questions_per_game: 10,
            question_seconds: 45,
            players: %{},
            rounds: [],
            question: nil,
            deadline: nil,
            overtime: false,
            answers: %{},
            sent: %{},
            draft: nil,
            judgements: %{},
            judged: false,
            played_again: false,
            final: %{votes: %{}, picked: nil, wagers: %{}, vote: nil, wager: nil}

  @type t :: %__MODULE__{}

  @doc "Fixed numbers the phone shares (protocol/fixtures/constants.json)."
  def constants do
    %{"vote_ms" => @vote_ms, "wager_ms" => @wager_ms, "final_wagers" => @final_wagers}
  end

  @doc "A new seat for the player whose Sporcle id is `me` (as in `sporcle_id//…`)."
  def new(me), do: %__MODULE__{me: me}

  @doc "Folds one Sporcle event in. `now` is the relay's clock in milliseconds."
  def apply_event(state, event, payload, now)

  def apply_event(s, "game_info", info, _now) do
    s =
      %{s | status: :live}
      |> put_players(info["allPlayers"])
      |> put_options(info["gameOptions"])
      |> put_pack(info["gamePack"])

    # The game_info that starts a game carries the round plan instead of the players.
    case info do
      %{"allRounds" => rounds} when is_list(rounds) ->
        %{new_game(s) | rounds: Enum.map(rounds, &plan_entry/1)}

      _ ->
        s
    end
  end

  def apply_event(s, "game_connect", info, now) do
    s = put_pack(%{s | status: :live}, info["gamePack"])

    cond do
      info["inLobby"] == true -> %{s | phase: :lobby, deadline: nil}
      view = info["currentView"] -> enter_view(s, view, info, now)
      true -> s
    end
  end

  def apply_event(s, event, %{"player" => player}, _now)
      when event in ~w(player_connect player_update player_login) do
    put_player(s, player, true)
  end

  def apply_event(s, "player_disconnect", %{"player" => player}, _now),
    do: put_player(s, player, false)

  def apply_event(s, "promote_to_host", _payload, _now) do
    update_player(s, s.peer_id, &%{&1 | host: true})
  end

  def apply_event(s, "game_question", %{"questionIndex" => index} = q, now) do
    if Map.has_key?(q, "question") do
      question = %{
        index: index,
        text: q["question"],
        category: q["questionCategory"],
        difficulty: q["questionDifficulty"],
        image_url: q["questionImgSrc"] || q["img_src"],
        final: index >= s.questions_per_game
      }

      %{
        s
        | phase: if(question.final, do: :final_question, else: :question),
          question: question,
          deadline: now + s.question_seconds * 1000,
          overtime: false,
          draft: nil,
          judgements: %{},
          judged: false
      }
    else
      # A question with no text opens the final round's vote. Sporcle sends it again if
      # the host restarts the final, but keeps the votes and wagers it already has, and
      # so does this; a new game starts the final clean (`new_game/1`).
      %{s | phase: :final_vote, question: nil, deadline: now + @vote_ms}
    end
  end

  def apply_event(s, "list_answers", %{"questionIndex" => index} = list, _now) do
    entries =
      for entry <- list["allPlayerAnswers"] || [], into: %{} do
        {entry["peerId"],
         %{
           text: entry["guessText"],
           wager: entry["wagerAmount"],
           correct: entry["correct"] == true,
           score: entry["score"]
         }}
      end

    s = %{s | answers: Map.put(s.answers, index, %{answer: list["answer"], entries: entries})}

    Enum.reduce(entries, s, fn {peer, entry}, s ->
      update_player(s, peer, &%{&1 | score: entry.score || &1.score})
    end)
  end

  def apply_event(s, "advance_all", %{"currentView" => view} = payload, now),
    do: enter_view(s, view, payload, now)

  def apply_event(s, "judgement_update", %{"playerJudgements" => judgements}, _now) do
    %{s | judgements: Map.new(judgements, fn {peer, ok} -> {to_int(peer), ok == true} end)}
  end

  # Settled marks end the final: the official app moves to its final scoreboard by itself,
  # and Sporcle sends nothing more (the host's advance_all "score" is only a shortcut).
  def apply_event(%{phase: :final_reveal} = s, "judged_answers", _payload, _now),
    do: %{s | judged: true, phase: :final_scores, deadline: nil}

  def apply_event(s, "judged_answers", _payload, _now), do: %{s | judged: true}

  def apply_event(s, "vote_final_round", %{"finalVotes" => votes}, _now),
    do: put_in(s.final.votes, votes)

  # Wagers can arrive with no CAST_WAGER before them: after a restarted final the server
  # skipped the vote it had already settled. Wagers mean the game is wagering.
  def apply_event(s, "list_final_wagers", %{"allPlayerFinalWagers" => wagers}, _now) do
    s = put_in(s.final.wagers, Map.new(wagers, &{&1["peerId"], &1["finalWager"]}))
    if s.phase == :final_vote, do: %{s | phase: :final_wager}, else: s
  end

  def apply_event(s, event, payload, _now) when event in ~w(next_game go_to_lobby) do
    s = put_pack(s, is_map(payload) && payload["gamePack"])
    %{new_game(s) | phase: :lobby, rounds: []}
  end

  def apply_event(s, "change_pack", %{"gamePack" => pack}, _now), do: put_pack(s, pack)

  def apply_event(s, "bounce", payload, _now) when is_map(payload) do
    if payload["playerId"] == s.me or (s.peer_id && payload["peerId"] == s.peer_id),
      do: %{s | status: :removed},
      else: s
  end

  def apply_event(s, _event, _payload, _now), do: s

  @doc "The upstream socket is gone."
  def lost(s), do: %{s | status: :lost}

  ## What this seat has done itself

  @doc "Records this seat's own answer as sent, so it is sent once and its wager spent."
  def sent(s, index, text, wager),
    do: %{s | sent: Map.put(s.sent, index, %{text: text, wager: wager})}

  @doc """
  Records this seat's own ready. Sporcle sends a `player_update` to the other players but
  not back to the one who sent it.
  """
  def ready(s, ready?), do: update_player(s, s.peer_id, &%{&1 | ready: ready?})

  def draft(s, text, wager), do: %{s | draft: %{text: text, wager: wager}}
  def voted(s, choice), do: put_in(s.final.vote, choice)
  def wagered(s, amount), do: put_in(s.final.wager, amount)
  def played_again(s), do: %{s | played_again: true}

  @doc "Records the lobby's pack as this seat changed it."
  def pack(s, pack), do: put_pack(s, pack)

  def judge(s, peer, correct?), do: %{s | judgements: Map.put(s.judgements, peer, correct?)}

  @doc """
  Question `index` has been over for `reveal_grace_ms/0`: the host may reveal it without
  everyone's answer. Nothing if the game has moved on.
  """
  def overtime(s, index) do
    if open?(s) and index(s) == index, do: %{s | overtime: true}, else: s
  end

  ## Derived

  def host?(s), do: match?(%{host: true}, s.players[s.peer_id])

  @doc "The question the game is on: open, or revealed and being judged."
  def index(%{question: %{index: index}}), do: index
  def index(_), do: nil

  @doc "This seat's answer to question `index`, sent or seen in `list_answers`."
  def own_answer(s, index) do
    case get_in(s.answers, [index, :entries, s.peer_id]) do
      nil -> s.sent[index]
      entry -> %{text: entry.text, wager: entry.wager}
    end
  end

  def answered?(s, index), do: own_answer(s, index) != nil

  def open?(s), do: s.phase in [:question, :final_question]

  @doc """
  Whether the host may reveal the open question: once every player who is playing (not
  spectating, still connected) has answered, or once it is in overtime. The official app
  enables its reveal button on the same terms.
  """
  def can_reveal?(s), do: open?(s) and (s.overtime or everyone_answered?(s))

  defp everyone_answered?(s) do
    index = index(s)
    entries = get_in(s.answers, [index, :entries]) || %{}

    Enum.all?(s.players, fn {peer, p} ->
      p.spectate or not p.connected or Map.has_key?(entries, peer) or
        (peer == s.peer_id and answered?(s, index))
    end)
  end

  def reveal_grace_ms, do: @reveal_grace_ms

  @doc """
  The wagers left for a regular question: each of 1..questions_per_game once a game.
  Sporcle does not check this (it accepted the same wager five times), so the relay does.
  """
  def wager_choices(s) do
    used =
      for index <- 0..(s.questions_per_game - 1)//1,
          answer = own_answer(s, index),
          do: answer.wager

    Enum.to_list(1..s.questions_per_game) -- used
  end

  def final_wagers, do: @final_wagers

  @doc """
  What the seat must do by itself at `now`. When a question's time runs out and this seat
  has not answered, the official app sends whatever was typed with the lowest wager left;
  the relay does the same, so a player whose phone is away never loses a turn.
  """
  def due(s, now) do
    index = index(s)

    cond do
      s.status != :live or s.deadline == nil or now < s.deadline -> []
      s.phase not in [:question, :final_question] or answered?(s, index) -> []
      true -> [{:answer, index, (s.draft && s.draft.text) || "", timeout_wager(s)}]
    end
  end

  defp timeout_wager(%{phase: :final_question} = s), do: s.final.wager || 0

  defp timeout_wager(s) do
    choices = wager_choices(s)
    draft = s.draft && s.draft.wager
    if draft in choices, do: draft, else: Enum.min(choices, fn -> 0 end)
  end

  ## Folding helpers

  defp enter_view(s, "GameShowAnswer", _payload, _now), do: %{s | phase: :reveal, deadline: nil}

  defp enter_view(s, "CAST_WAGER", payload, now) do
    s = put_in(s.final.picked, payload["pickedVote"] || s.final.picked)
    %{s | phase: :final_wager, question: nil, deadline: now + @wager_ms}
  end

  defp enter_view(s, "showAnswer", _payload, _now), do: %{s | phase: :final_reveal, deadline: nil}
  defp enter_view(s, "score", _payload, _now), do: %{s | phase: :final_scores, deadline: nil}
  defp enter_view(s, _view, _payload, _now), do: s

  defp new_game(s) do
    %{
      s
      | question: nil,
        deadline: nil,
        answers: %{},
        sent: %{},
        draft: nil,
        judgements: %{},
        judged: false,
        played_again: false,
        final: %{votes: %{}, picked: nil, wagers: %{}, vote: nil, wager: nil}
    }
  end

  defp put_players(s, players) when is_list(players) do
    Enum.reduce(players, %{s | players: %{}}, &put_player(&2, &1, true))
  end

  defp put_players(s, _), do: s

  defp put_player(s, %{"peerId" => peer} = p, connected?) do
    player = %{
      peer_id: peer,
      player_id: p["playerId"],
      name: p["teamName"] || p["sporcleHandle"],
      host: p["isHost"] == true,
      connected: connected?,
      ready: p["readyForGame"] == true,
      spectate: p["spectate"] == true,
      score: p["score"] || get_in(s.players, [peer, :score]) || 0
    }

    s = %{s | players: Map.put(s.players, peer, player)}
    if p["playerId"] == s.me, do: %{s | peer_id: peer}, else: s
  end

  defp put_player(s, _, _), do: s

  defp update_player(s, peer, fun) do
    case s.players[peer] do
      nil -> s
      player -> %{s | players: Map.put(s.players, peer, fun.(player))}
    end
  end

  defp put_options(s, %{} = options) do
    %{
      s
      | questions_per_game: options["QUESTIONS_PER_GAME"] || s.questions_per_game,
        question_seconds: options["QUESTION_SECONDS"] || s.question_seconds
    }
  end

  defp put_options(s, _), do: s

  defp put_pack(s, %{} = pack) do
    %{
      s
      | pack: %{
          id: pack["id"],
          name: pack["name"],
          description: pack["description"],
          image_url: if(pack["img_src"] in [nil, ""], do: nil, else: pack["img_src"]),
          num_questions: pack["num_questions"],
          has_images: pack["has_images"] == true
        }
    }
  end

  defp put_pack(s, _), do: s

  defp plan_entry(r), do: %{index: r["questionIndex"], percent: to_int(r["percent"])}

  defp to_int(n) when is_integer(n), do: n

  defp to_int(n) when is_binary(n) do
    case Integer.parse(n) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp to_int(_), do: nil
end
