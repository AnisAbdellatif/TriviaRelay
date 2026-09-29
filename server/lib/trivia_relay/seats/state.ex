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
  @final_votes ~w(easy medium hard)
  @questions_per_game [5, 10, 15, 20]
  @question_seconds [15, 30, 45, 60]
  # How long after a question's time runs out the host may reveal it without everyone's
  # answer, as in the official app.
  @reveal_grace_ms 5_000

  # Everything here comes from Sporcle, and through it from any player in the game: a
  # hostile one can send any JSON at all. Events are type-checked part by part, what does
  # not fit is ignored, and what is kept is bounded, so no event can crash the seat or grow
  # it without limit. The bounds are far above anything a real game sends.
  @max_players 100
  # Question indexes: the regular questions (at most 20) and the final's candidates.
  @max_index 63
  @max_name 64
  @max_text 200
  @max_long_text 2_000
  # JSON numbers the app can hold as integers.
  @max_int 9_007_199_254_740_991

  defguardp int?(n) when is_integer(n) and n >= -@max_int and n <= @max_int

  defstruct me: nil,
            peer_id: nil,
            status: :connecting,
            # Once `removed`: whether Sporcle lets the player join this game again.
            can_rejoin: true,
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

  def apply_event(s, "game_info", %{} = info, _now) do
    s =
      %{s | status: :live}
      |> put_players(info["allPlayers"])
      |> put_options(info["gameOptions"])
      |> put_pack(info["gamePack"])

    # The game_info that starts a game carries the round plan instead of the players.
    case info do
      %{"allRounds" => rounds} when is_list(rounds) ->
        %{new_game(s) | rounds: plan(rounds)}

      _ ->
        s
    end
  end

  def apply_event(s, "game_connect", %{} = info, now) do
    s = put_pack(%{s | status: :live}, info["gamePack"])

    cond do
      info["inLobby"] == true -> %{s | phase: :lobby, deadline: nil}
      is_binary(info["currentView"]) -> enter_view(s, info["currentView"], info, now)
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

  def apply_event(s, "game_question", %{"questionIndex" => index} = q, now)
      when is_integer(index) and index in 0..@max_index do
    if Map.has_key?(q, "question") do
      question = %{
        index: index,
        text: text(q["question"], @max_long_text) || "",
        category: text(q["questionCategory"], @max_text),
        difficulty: difficulty(q["questionDifficulty"]),
        image_url: text(q["questionImgSrc"] || q["img_src"], @max_long_text),
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

  def apply_event(s, "list_answers", %{"questionIndex" => index} = list, _now)
      when is_integer(index) and index in 0..@max_index do
    case list["allPlayerAnswers"] || [] do
      answers when is_list(answers) -> put_answers(s, index, list["answer"], answers)
      _ -> s
    end
  end

  def apply_event(s, "advance_all", %{"currentView" => view} = payload, now)
      when is_binary(view),
      do: enter_view(s, view, payload, now)

  def apply_event(s, "judgement_update", %{"playerJudgements" => judgements}, _now)
      when is_map(judgements) do
    %{s | judgements: judgements(s, judgements)}
  end

  # Settled marks end the final: the official app moves to its final scoreboard by itself,
  # and Sporcle sends nothing more (the host's advance_all "score" is only a shortcut).
  def apply_event(%{phase: :final_reveal} = s, "judged_answers", _payload, _now),
    do: %{s | judged: true, phase: :final_scores, deadline: nil}

  def apply_event(s, "judged_answers", _payload, _now), do: %{s | judged: true}

  def apply_event(s, "vote_final_round", %{"finalVotes" => votes}, _now) when is_map(votes) do
    votes = for {choice, n} <- votes, choice in @final_votes, int?(n), into: %{}, do: {choice, n}
    put_in(s.final.votes, votes)
  end

  # Wagers can arrive with no CAST_WAGER before them: after a restarted final the server
  # skipped the vote it had already settled. Wagers mean the game is wagering.
  def apply_event(s, "list_final_wagers", %{"allPlayerFinalWagers" => wagers}, _now)
      when is_list(wagers) do
    wagers =
      for %{"peerId" => peer, "finalWager" => wager} <- first(wagers, @max_players),
          int?(peer) and int?(wager),
          into: %{},
          do: {peer, wager}

    s = put_in(s.final.wagers, wagers)
    if s.phase == :final_vote, do: %{s | phase: :final_wager}, else: s
  end

  def apply_event(s, event, payload, _now) when event in ~w(next_game go_to_lobby) do
    s = put_pack(s, is_map(payload) && payload["gamePack"])
    %{new_game(s) | phase: :lobby, rounds: []}
  end

  def apply_event(s, "change_pack", %{"gamePack" => pack}, _now), do: put_pack(s, pack)

  # Sporcle sends `bounce` only to the player the host removed, and the official app never
  # checks whom it names (decompiled). `noReturn` is the host's "Kick" rather than "Eject";
  # `reject` is a kicked player trying to come back.
  def apply_event(s, "bounce", payload, _now) do
    payload = if is_map(payload), do: payload, else: %{}

    %{
      s
      | status: :removed,
        can_rejoin: !(payload["noReturn"] == true or payload["reject"] == true)
    }
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

  @doc "Whether this seat's own player is marked ready (nil when it isn't known yet)."
  def ready?(s), do: get_in(s.players, [s.peer_id, :ready])

  def draft(s, text, wager), do: %{s | draft: %{text: text, wager: wager}}

  @doc """
  Takes over what `old`, an earlier seat of the same player in the same game, had spent:
  its answers (so a question is answered once, and each wager used once) and its final
  vote and wager. Sporcle gives a rejoining player back their place, but only resends the
  current question's answers, so a new seat would otherwise start with every wager.
  """
  def carry_over(s, %__MODULE__{} = old) do
    sent =
      for index <- 0..@max_index,
          answer = own_answer(old, index),
          into: s.sent,
          do: {index, answer}

    %{
      s
      | sent: sent,
        final: %{
          s.final
          | vote: s.final.vote || old.final.vote,
            wager: s.final.wager || final_wager(old)
        }
    }
  end

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

  def player?(s, peer), do: Map.has_key?(s.players, peer)

  @doc "The question the game is on: open, or revealed and being judged."
  def index(%{question: %{index: index}}), do: index
  def index(_), do: nil

  @doc "This seat's answer to question `index`, sent or seen in `list_answers`."
  def own_answer(s, index) do
    case get_in(s.answers, [index, :entries, s.peer_id]) do
      nil -> s.sent[index]
      entry -> %{text: entry.text || "", wager: entry.wager || 0}
    end
  end

  @doc "This seat's final wager: placed from here, or seen in `list_final_wagers`."
  def final_wager(s), do: s.final.wager || s.final.wagers[s.peer_id]

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
  def final_votes, do: @final_votes
  def questions_per_game_choices, do: @questions_per_game
  def question_seconds_choices, do: @question_seconds

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

  defp timeout_wager(%{phase: :final_question} = s), do: final_wager(s) || 0

  defp timeout_wager(s) do
    choices = wager_choices(s)
    draft = s.draft && s.draft.wager
    if draft in choices, do: draft, else: Enum.min(choices, fn -> 0 end)
  end

  ## Folding helpers

  defp enter_view(s, "GameShowAnswer", _payload, _now), do: %{s | phase: :reveal, deadline: nil}

  defp enter_view(s, "CAST_WAGER", payload, now) do
    picked = payload["pickedVote"]
    s = if picked in @final_votes, do: put_in(s.final.picked, picked), else: s
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

  defp put_answers(s, index, answer, answers) do
    entries =
      for %{"peerId" => peer} = entry <- Enum.take(answers, @max_players),
          int?(peer),
          into: %{} do
        {peer,
         %{
           text: text(entry["guessText"], @max_text),
           wager: integer(entry["wagerAmount"]),
           correct: entry["correct"] == true,
           score: integer(entry["score"])
         }}
      end

    answer = %{answer: text(answer, @max_long_text), entries: entries}
    s = %{s | answers: Map.put(s.answers, index, answer)}

    Enum.reduce(entries, s, fn {peer, entry}, s ->
      update_player(s, peer, &%{&1 | score: entry.score || &1.score})
    end)
  end

  defp put_players(s, players) when is_list(players) do
    Enum.reduce(players, %{s | players: %{}}, &put_player(&2, &1, true))
  end

  defp put_players(s, _), do: s

  # Players past `@max_players` are left out, except this seat's own.
  defp put_player(s, %{"peerId" => peer} = p, connected?) when int?(peer) do
    me? = p["playerId"] == s.me

    if map_size(s.players) >= @max_players and not Map.has_key?(s.players, peer) and not me? do
      s
    else
      player = %{
        peer_id: peer,
        player_id: text(p["playerId"], @max_text),
        name:
          text(p["teamName"], @max_name) || text(p["sporcleHandle"], @max_name) ||
            "Player #{peer}",
        host: p["isHost"] == true,
        connected: connected?,
        ready: p["readyForGame"] == true,
        spectate: p["spectate"] == true,
        score: integer(p["score"]) || get_in(s.players, [peer, :score]) || 0
      }

      s = %{s | players: Map.put(s.players, peer, player)}
      if me?, do: %{s | peer_id: peer}, else: s
    end
  end

  defp put_player(s, _, _), do: s

  defp update_player(s, peer, fun) do
    case s.players[peer] do
      nil -> s
      player -> %{s | players: Map.put(s.players, peer, fun.(player))}
    end
  end

  # Only the values the game offers (constants.json): anything else would break the
  # wagers and the clock, so the seat keeps what it had.
  defp put_options(s, %{} = options) do
    per_game = options["QUESTIONS_PER_GAME"]
    seconds = options["QUESTION_SECONDS"]

    %{
      s
      | questions_per_game:
          if(per_game in @questions_per_game, do: per_game, else: s.questions_per_game),
        question_seconds: if(seconds in @question_seconds, do: seconds, else: s.question_seconds)
    }
  end

  defp put_options(s, _), do: s

  # A pack the app could not show (no id or name) is ignored.
  defp put_pack(s, %{} = pack) do
    with id when is_integer(id) <- to_int(pack["id"]),
         name when is_binary(name) <- text(pack["name"], @max_text) do
      %{
        s
        | pack: %{
            id: id,
            name: name,
            description: text(pack["description"], @max_long_text),
            image_url: if(pack["img_src"] != "", do: text(pack["img_src"], @max_long_text)),
            num_questions: integer(pack["num_questions"]),
            has_images: pack["has_images"] == true
          }
      }
    else
      _ -> s
    end
  end

  defp put_pack(s, _), do: s

  defp plan(rounds) do
    for %{"questionIndex" => index} = r <- first(rounds, @max_index + 1),
        int?(index),
        do: %{index: index, percent: to_int(r["percent"])}
  end

  # The host's marks, for players in the game only.
  defp judgements(s, judgements) do
    for {peer, ok} <- judgements,
        peer = to_int(peer),
        Map.has_key?(s.players, peer),
        into: %{},
        do: {peer, ok == true}
  end

  defp first(list, n) when is_list(list), do: Enum.take(list, n)
  defp first(_, _), do: []

  defp text(value, max) when is_binary(value), do: String.slice(value, 0, max)
  defp text(_, _), do: nil

  # Sporcle sends it as a string ("90").
  defp difficulty(n) when int?(n), do: Integer.to_string(n)
  defp difficulty(n), do: text(n, 16)

  defp integer(n) when int?(n), do: n
  defp integer(_), do: nil

  defp to_int(n) when int?(n), do: n

  defp to_int(n) when is_binary(n) and byte_size(n) <= 16 do
    case Integer.parse(n) do
      {i, _} -> i
      :error -> nil
    end
  end

  defp to_int(_), do: nil
end
