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
  # The official app's clock between the wagers and the final question.
  @wait_ms 15_000
  @final_wagers [0, 10, 20]
  @final_votes ~w(easy medium hard)
  # The official app's MAX_PACK_VOTES: packs one player may vote for, per game.
  @max_pack_votes 5
  @questions_per_game [5, 10, 15, 20]
  @question_seconds [15, 30, 45, 60]
  # How long after a question's time runs out the host may reveal it without everyone's
  # answer, as in the official app.
  @reveal_grace_ms 5_000
  # The official app's countdowns before the first question ("We're starting in") and
  # the final one ("Final question in"): each client counts down from the question's
  # arrival, and only then shows it and starts its clock.
  @start_countdown_ms 5_000
  @final_countdown_ms 3_000
  # How long a notice shows: the official app's banner default (4.75 s), rounded up.
  @notice_ms 5_000
  # A `server_message` shows for its own `interval` (ms), within these; 0 is "until
  # dismissed" in the official app, here the longest.
  @min_notice_ms 1_000
  @max_notice_ms 60_000
  @server_message_types ~w(info warn error success)

  # The game's chat (the official app's MessageBoard, decompiled). Its field takes 256
  # characters; the relay keeps the last `@chat_history` messages, and a snapshot carries
  # the last `@chat_window` of them, more once the phone asks (`chat_more`).
  @chat_max_length 256
  @chat_history 50
  @chat_window 20
  # A message from anyone may be longer than the official field allows; this is only a
  # bound, and cuts nothing a real one would say.
  @chat_in_max 512
  @max_typing 20

  # Reactions ("sound honks", the official app's `send_u2u` and `honk`): a sound one player
  # sends another. Only the goose (the Honk) is free; the rest come in Sporcle's paid sound
  # packs, so the relay sends the goose alone, and plays any it receives.
  @free_reactions ~w(goose)
  @reaction_types ~w(goose cow donkey goat rooster sheep soccer_cheer aww clap ooh laugh
                     accordion rim_shot trombone trumpet tuba)
  # The official app sends a honk at most every 2 s (a leading throttle on `sendHonk`), and
  # plays one at most every 250 ms. A received one shows for `@reaction_ms`.
  @reaction_gap_ms 2_000
  @reaction_play_gap_ms 250
  @reaction_ms 4_000
  @max_reactions 10
  @recent_reactions 5

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
  # Packs in the lobby's votes.
  @max_voted_packs 100
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
            final: %{votes: %{}, picked: nil, wagers: %{}, vote: nil, wager: nil},
            # Something to tell the player for a moment: %{kind, level, title, message, until}.
            notice: nil,
            # The count down to a question's showing: %{kind, until}.
            countdown: nil,
            # The lobby's pack votes, by pack id: %{game_pack, pack, voters} (`voters` are
            # Sporcle player ids; `game_pack` is Sporcle's own map, sent back to vote).
            pack_votes: %{},
            # This seat's thumbs on questions and its reports, by question index.
            ratings: %{},
            reports: %{},
            # The regular wagers Sporcle says this player has used this game.
            used_wagers: MapSet.new(),
            # The next game's code, when the game moved on without this seat.
            next_game_code: nil,
            # The game's chat. `messages` oldest first; `unread` counts other players'
            # messages since the chat was last open here; `typing` is who Sporcle says is
            # typing (player id => name); `open` is whether the relay told Sporcle this
            # player has the chat open, and `typing_sent` whether it said they are typing.
            chat: %{
              messages: [],
              unread: 0,
              typing: %{},
              open: false,
              typing_sent: false,
              window: @chat_window,
              more: false,
              page: 0,
              loading: false,
              seq: 0
            },
            # Reactions: `received`, the ones other players sent this one (%{id, from, type,
            # at, until}, oldest first); `sent_at`, when this seat last sent one; `counts`,
            # what each player has had, by Sporcle player id (%{total, recent}).
            reactions: %{received: [], seq: 0, sent_at: nil, counts: %{}},
            # The Party Poppers Sporcle said the player had as they took the seat, less the
            # ones spent since; nil when it didn't say.
            poppers: nil

  @type t :: %__MODULE__{}

  @doc "Fixed numbers the phone shares (protocol/fixtures/constants.json)."
  def constants do
    %{
      "vote_ms" => @vote_ms,
      "wager_ms" => @wager_ms,
      "final_wagers" => @final_wagers,
      "max_pack_votes" => @max_pack_votes,
      "start_countdown_ms" => @start_countdown_ms,
      "final_countdown_ms" => @final_countdown_ms,
      "chat_max_length" => @chat_max_length,
      "reaction_types" => @free_reactions,
      "reaction_sounds" => @reaction_types,
      "reaction_gap_ms" => @reaction_gap_ms,
      "reaction_ms" => @reaction_ms
    }
  end

  @doc """
  A new seat for the player whose Sporcle id is `me` (as in `sporcle_id//…`), who had
  `poppers` Party Poppers as they took it (nil when Sporcle didn't say).
  """
  def new(me, poppers \\ nil), do: %__MODULE__{me: me, poppers: poppers}

  @doc "Folds one Sporcle event in. `now` is the relay's clock in milliseconds."
  def apply_event(state, event, payload, now)

  def apply_event(s, "game_info", %{} = info, _now) do
    arrival? = s.status == :connecting

    s =
      %{s | status: :live}
      |> put_players(info["allPlayers"])
      |> put_options(info["gameOptions"])
      |> put_pack(info["gamePack"])

    # The game_info that starts a game carries the round plan instead of the players. The
    # first one a seat gets is its own arrival, though, the game as it stands: whatever it
    # carries, it starts nothing, so a seat that took over another's (`carry_over/2`) keeps
    # what that one had spent.
    case info do
      %{"allRounds" => rounds} when is_list(rounds) and arrival? -> %{s | rounds: plan(rounds)}
      %{"allRounds" => rounds} when is_list(rounds) -> %{new_game(s) | rounds: plan(rounds)}
      _ -> s
    end
  end

  # Where a seat arrives: the lobby, or a game under way (a late join, or a rejoin), when
  # it carries the question the game is on, how long it has been open, and what this
  # player has spent (confirmed live for a rejoin during a reveal).
  def apply_event(s, "game_connect", %{} = info, now) do
    s =
      %{s | status: :live}
      |> put_pack(info["gamePack"])
      |> put_pack_votes(info["packVotes"])

    if info["inLobby"] == true,
      do: %{s | phase: :lobby, deadline: nil},
      else: join_game_under_way(s, info, now)
  end

  # The wagers this player has used this game, as Sporcle keeps them: `{"<wager>": mark}`
  # (the mark is true or false once judged, null before).
  def apply_event(s, "update_wagers", %{"wagers" => wagers}, _now), do: put_used_wagers(s, wagers)

  # Sent to players still on the final scores when the next game is made without them:
  # its code, to join it with (the official app's Play Again then joins it).
  def apply_event(%{phase: :final_scores} = s, "leave_behind", %{"gameCode" => code}, _now) do
    if is_binary(code) and code =~ ~r/^\d{4,8}$/, do: %{s | next_game_code: code}, else: s
  end

  def apply_event(s, event, %{"player" => player}, _now)
      when event in ~w(player_connect player_update player_login) do
    put_player(s, player, true)
  end

  def apply_event(s, "player_disconnect", %{"player" => player}, _now),
    do: put_player(s, player, false)

  # The official app says so in a banner: the host left, or handed the game over.
  def apply_event(s, "promote_to_host", payload, now) do
    left? = is_map(payload) and payload["oldHostLeft"] == true

    s
    |> update_player(s.peer_id, &%{&1 | host: true})
    |> notice(if(left?, do: "host_left", else: "promoted"), now)
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

      countdown = countdown(s, question, now)
      starts = if countdown, do: countdown.until, else: now

      %{
        s
        | phase: if(question.final, do: :final_question, else: :question),
          question: question,
          countdown: countdown,
          deadline: starts + s.question_seconds * 1000,
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
    # `playerWagers` is this player's own used wagers, sent to each player with every list
    # (confirmed live).
    s = put_used_wagers(s, list["playerWagers"])

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

  def apply_event(s, "next_game", payload, _now), do: to_lobby(s, payload)

  # The host's "Go to Lobby" mid-game. Everybody else is told, as the official app does;
  # the host sent it.
  def apply_event(s, "go_to_lobby", payload, now) do
    s = to_lobby(s, payload)
    if host?(s), do: s, else: notice(s, "to_lobby", now)
  end

  def apply_event(s, "change_pack", %{"gamePack" => pack}, _now), do: put_pack(s, pack)

  # A message from Sporcle to everyone in the game, shown by the official app as a banner:
  # `{type, title, message, interval}`, `interval` being how long it shows (ms).
  def apply_event(s, "server_message", %{} = m, now) do
    title = text(m["title"], @max_text)
    message = text(m["message"], @max_long_text)

    if blank?(title) and blank?(message) do
      s
    else
      level = if m["type"] in @server_message_types, do: m["type"], else: "info"

      ms =
        case m["interval"] do
          0 -> @max_notice_ms
          n when is_number(n) -> n |> round() |> max(@min_notice_ms) |> min(@max_notice_ms)
          _ -> @notice_ms
        end

      %{
        s
        | notice: %{kind: "server", level: level, title: title, message: message, until: now + ms}
      }
    end
  end

  def apply_event(s, "pack_votes", %{"packVotes" => votes}, _now), do: put_pack_votes(s, votes)

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

  # The chat's history, as Sporcle sends it when the chat opens (`chat_load`) and as the
  # player scrolls back (`chat_load_more`): `{messages, hasMore}`, GiftedChat's messages,
  # newest first. Opening the chat reads it (the official app clears its unread dot).
  def apply_event(s, "chat_load", %{"messages" => messages} = page, now) when is_list(messages) do
    s = put_chat_page(s, messages, now)
    chat = %{s.chat | more: page["hasMore"] == true, loading: false, page: 0, unread: 0}
    %{s | chat: chat}
  end

  def apply_event(s, "chat_load_more", %{"messages" => messages} = page, now)
      when is_list(messages) do
    s = put_chat_page(s, messages, now)
    %{s | chat: %{s.chat | more: page["hasMore"] == true, loading: false}}
  end

  # A message as it is sent, to players with the chat open (`chat_message`), and the latest
  # one for everybody's chat button (`last_chat_message`): `{message}`, one GiftedChat
  # message. Whoever sent it is no longer typing.
  def apply_event(s, event, %{"message" => %{} = message}, now)
      when event in ~w(chat_message last_chat_message) do
    case chat_message(message, now, now) do
      nil -> s
      m -> add_chat(s, m)
    end
  end

  # "There is something new in the chat", with nothing of it: the official app's red dot.
  def apply_event(%{chat: %{open: false, unread: 0}} = s, "chat_has_message", _payload, _now),
    do: put_in(s.chat.unread, 1)

  def apply_event(s, "chat_has_message", _payload, _now), do: s

  # Who is typing, as a whole: `{whoseTyping: {<player id>: <name>}}`.
  def apply_event(s, "chat_typing", %{"whoseTyping" => %{} = typing}, _now) do
    typing =
      for {id, name} <- Enum.take(typing, @max_typing),
          is_binary(id),
          into: %{},
          do: {text(id, @max_text), clean_name(name)}

    put_in(s.chat.typing, typing)
  end

  # A reaction another player sent this one: `honk {peerId, honk_type}`, `peerId` being
  # the sender, sent to this player alone. The official app plays it, at most one every
  # 250 ms, and never its own.
  def apply_event(s, "honk", %{"peerId" => from} = honk, now) when int?(from) do
    type = honk["honk_type"]

    cond do
      from == s.peer_id -> s
      not (is_binary(type) and type =~ ~r/\A[a-z0-9_]{1,32}\z/) -> s
      recently_reacted?(s, now) -> s
      true -> add_reaction(s, from, type, now)
    end
  end

  # The reactions everybody has had: `{u2u: {<player id>: {total, stream, byType}},
  # u2uPerf}`. `stream` is the latest, as "<type>-<id>". The whole list each time.
  def apply_event(s, "list_u2u", %{"u2u" => %{} = u2u}, _now) do
    u2u =
      for {id, %{} = counts} <- Enum.take(u2u, @max_players),
          is_binary(id),
          into: %{},
          do: {text(id, @max_text), u2u_counts(counts)}

    put_in(s.reactions.counts, u2u)
  end

  # Joining a game with pictures costs a player who isn't its host a Party Popper, spent
  # as play starts: the official app takes one off its count and says so.
  def apply_event(s, "popper_spent", _payload, now) do
    poppers = if s.poppers, do: max(s.poppers - 1, 0)
    notice(%{s | poppers: poppers}, "popper_spent", now)
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

  @doc """
  Records whether this seat's host spectates, as it changed it: the official app does the
  same, then takes what Sporcle's next `player_update` says.
  """
  def spectate(s, spectate?), do: update_player(s, s.peer_id, &%{&1 | spectate: spectate?})

  @doc "Whether this seat's own player is marked ready (nil when it isn't known yet)."
  def ready?(s), do: get_in(s.players, [s.peer_id, :ready])

  def draft(s, text, wager), do: %{s | draft: %{text: text, wager: wager}}

  @doc """
  Takes over what `old`, an earlier seat of the same player in the same game, had spent:
  its answers (so a question is answered once, and each wager used once), the wagers
  Sporcle listed as used, its ratings and reports, and its final vote and wager. Sporcle
  gives a rejoining player back their place and says what they spent (`game_connect`'s
  `usedWagers` and `questions`, folded in as they come), but this doesn't wait on it. The
  new seat's first `game_info` never starts a new game, so none of this is wiped by it.
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
        used_wagers: MapSet.union(s.used_wagers, old.used_wagers),
        ratings: Map.merge(old.ratings, s.ratings),
        reports: Map.merge(old.reports, s.reports),
        chat: %{s.chat | messages: merge_chat(old.chat.messages, s.chat.messages)},
        final: %{
          s.final
          | vote: s.final.vote || old.final.vote,
            wager: s.final.wager || final_wager(old)
        }
    }
  end

  def voted(s, choice), do: put_in(s.final.vote, choice)

  @doc """
  Records this seat's vote for a lobby pack (`game_pack`, Sporcle's map, and `pack`, as
  the seat keeps it), or its taking one back, ahead of Sporcle's next `pack_votes`.
  """
  def pack_vote(s, game_pack, pack, vote?) do
    entry = s.pack_votes[pack.id] || %{game_pack: game_pack, pack: pack, voters: []}
    voters = List.delete(entry.voters, s.me)
    voters = if vote?, do: voters ++ [s.me], else: voters

    votes =
      if voters == [],
        do: Map.delete(s.pack_votes, pack.id),
        else: Map.put(s.pack_votes, pack.id, %{entry | voters: voters})

    %{s | pack_votes: votes}
  end

  @doc "The packs this seat's player has voted for."
  def own_pack_votes(s),
    do: for({id, %{voters: voters}} <- s.pack_votes, s.me in voters, do: id)

  def max_pack_votes, do: @max_pack_votes

  @doc "The lobby pack `id` as Sporcle sent it, and as the seat keeps it; nil if nobody voted for it."
  def voted_pack(s, id) do
    case s.pack_votes[id] do
      nil -> nil
      entry -> {entry.game_pack, entry.pack}
    end
  end

  @doc "A pack from Sporcle (`getPack`, `change_pack`) as the seat keeps it, or nil."
  def read_pack(game_pack), do: put_pack(%__MODULE__{}, game_pack).pack

  def rated(s, index, rating), do: %{s | ratings: Map.put(s.ratings, index, rating)}
  def reported(s, index, reason), do: %{s | reports: Map.put(s.reports, index, reason)}

  @doc """
  The question this player may rate or report now, as the official app offers it: once
  they have answered it, and while it is revealed. Nil otherwise.
  """
  def rateable(s) do
    index = index(s)

    cond do
      index == nil -> nil
      s.phase in [:reveal, :final_reveal] -> index
      open?(s) and answered?(s, index) -> index
      true -> nil
    end
  end

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

  ## The chat and reactions, as this seat takes part

  @doc "The relay told Sporcle this player has the chat open: what is in it is read."
  def chat_opened(s), do: %{s | chat: %{s.chat | open: true, unread: 0}}

  @doc "The relay told Sporcle the chat is closed: the next opening shows the latest again."
  def chat_closed(s),
    do: %{s | chat: %{s.chat | open: false, typing_sent: false, window: @chat_window}}

  @doc "Records whether the relay told Sporcle this player is typing."
  def chat_typing(s, typing?), do: put_in(s.chat.typing_sent, typing?)

  @doc """
  Records this seat's own message as sent (`message` as it went to Sporcle, at `now`):
  Sporcle doesn't send a player's own message back, as the official app shows it itself.
  """
  def chat_sent(s, %{} = message, now) do
    case chat_message(message, now, now) do
      nil -> s
      m -> add_chat(s, m)
    end
  end

  @doc """
  The phone asked for earlier messages: `{:show, state}` when the relay has them, or
  `{:fetch, page, state}` when Sporcle has to be asked for page `page`, or `:none`.
  """
  def chat_more(%{chat: chat} = s) do
    kept = length(chat.messages)

    cond do
      kept > chat.window ->
        {:show, put_in(s.chat.window, min(chat.window + @chat_window, @chat_history))}

      chat.more and chat.open and not chat.loading and kept < @chat_history ->
        page = chat.page + 1
        window = min(chat.window + @chat_window, @chat_history)
        {:fetch, page, %{s | chat: %{chat | page: page, loading: true, window: window}}}

      true ->
        :none
    end
  end

  def chat_max_length, do: @chat_max_length
  def chat_history, do: @chat_history

  @doc "Whether this seat may send a reaction at `now`: one every `@reaction_gap_ms`."
  def may_react?(%{reactions: %{sent_at: nil}}, _now), do: true
  def may_react?(s, now), do: now - s.reactions.sent_at >= @reaction_gap_ms

  def reacted(s, now), do: put_in(s.reactions.sent_at, now)
  def free_reactions, do: @free_reactions

  @doc "The chat as a snapshot shows it: the last `window` messages."
  def chat_shown(s), do: Enum.take(s.chat.messages, -s.chat.window)

  @doc "Whether there is more of the chat before what a snapshot shows."
  def chat_more?(%{chat: chat}) do
    kept = length(chat.messages)
    kept > chat.window or (chat.more and kept < @chat_history)
  end

  ## Derived

  def host?(s), do: match?(%{host: true}, s.players[s.peer_id])

  @doc "Whether this seat's player watches rather than plays (a host hosting as a spectator)."
  def spectating?(s), do: match?(%{spectate: true}, s.players[s.peer_id])

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

    Enum.reject(1..s.questions_per_game, &(&1 in used or MapSet.member?(s.used_wagers, &1)))
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
    if s.status == :live and s.deadline != nil and now >= s.deadline and owes_answer?(s),
      do: [{:answer, index(s), (s.draft && s.draft.text) || "", timeout_wager(s)}],
      else: []
  end

  # An open question this player hasn't answered, and plays (a spectator never answers).
  defp owes_answer?(s), do: open?(s) and not answered?(s, index(s)) and not spectating?(s)

  defp timeout_wager(%{phase: :final_question} = s), do: final_wager(s) || 0

  defp timeout_wager(s) do
    choices = wager_choices(s)
    draft = s.draft && s.draft.wager
    if draft in choices, do: draft, else: Enum.min(choices, fn -> 0 end)
  end

  ## Folding helpers

  # The game's first question, and the final one, come after a countdown on every client,
  # and their clocks start after it.
  defp countdown(_s, %{final: true}, now), do: %{kind: "final", until: now + @final_countdown_ms}

  defp countdown(%{phase: :lobby}, _question, now),
    do: %{kind: "start", until: now + @start_countdown_ms}

  defp countdown(_s, _question, _now), do: nil

  defp enter_view(s, "GameShowAnswer", _payload, _now), do: %{s | phase: :reveal, deadline: nil}

  defp enter_view(s, "CAST_WAGER", payload, now) do
    picked = payload["pickedVote"]
    s = if picked in @final_votes, do: put_in(s.final.picked, picked), else: s
    %{s | phase: :final_wager, question: nil, deadline: now + @wager_ms}
  end

  defp enter_view(s, "showAnswer", _payload, _now), do: %{s | phase: :final_reveal, deadline: nil}
  defp enter_view(s, "score", _payload, _now), do: %{s | phase: :final_scores, deadline: nil}
  defp enter_view(s, _view, _payload, _now), do: s

  # A game under way, from `game_connect`: every `currentView` the official app knows, by
  # the question it is on (the regular round's, or past them the final's). A question's
  # clock started `timeElapsed` seconds before (Sporcle's seconds; the official app counts
  # the rest down), and the seat keeps what this player already spent.
  defp join_game_under_way(s, info, now) do
    index = info["questionIndex"]
    view = if is_binary(info["currentView"]), do: info["currentView"]
    elapsed = if is_number(info["timeElapsed"]), do: info["timeElapsed"], else: 0
    elapsed_ms = elapsed |> max(0) |> min(3_600) |> Kernel.*(1000) |> round()

    s =
      s
      |> put_used_wagers(info["usedWagers"])
      |> put_own_answers(info["questions"])

    cond do
      not (is_integer(index) and index in 0..@max_index) ->
        # Nothing to place the seat by: only a view the relay can act on without a question.
        enter_view(s, view, info, now)

      index < s.questions_per_game ->
        join_regular(s, view, info, joined_question(info, index, false), now - elapsed_ms)

      true ->
        s = put_picked(s, info["pickedVote"])
        join_final(s, view, info, index, now - elapsed_ms)
    end
  end

  # The regular round: answering (or waiting on the others, answered), revealed, or the
  # scores between questions, which follow the marks. A view it doesn't know is taken as
  # answering, which is what the official app shows first.
  defp join_regular(s, view, info, question, _started)
       when view in ["GameShowAnswer", "MidRoundScores"] do
    judged? = view == "MidRoundScores" or info["judgeSubmitted"] == true
    %{s | phase: :reveal, question: question, deadline: nil, judged: judged?}
  end

  defp join_regular(s, _view, _info, question, started), do: open_question(s, question, started)

  defp join_final(s, view, _info, _index, started) when view in ["VOTE_CATEGORY", "voteCategory"],
    do: %{s | phase: :final_vote, question: nil, deadline: started + @vote_ms}

  defp join_final(s, "CAST_WAGER", _info, _index, started),
    do: %{s | phase: :final_wager, question: nil, deadline: started + @wager_ms}

  # Wagers in, waiting for the host to ask the question.
  defp join_final(s, "wait", _info, _index, started),
    do: %{s | phase: :final_wager, question: nil, deadline: started + @wait_ms}

  defp join_final(s, view, info, index, started) when view in ["question", "answered"],
    do: open_question(s, joined_question(info, index, true), started)

  # The final revealed: over already once the marks are in, as the official app takes it.
  defp join_final(s, view, info, index, _started) when view in ["showAnswer", "FINAL_REVEAL"] do
    phase = if info["judgeSubmitted"] == true, do: :final_scores, else: :final_reveal

    %{
      s
      | phase: phase,
        question: joined_question(info, index, true),
        deadline: nil,
        judged: phase == :final_scores
    }
  end

  defp join_final(s, "score", _info, _index, _started),
    do: %{s | phase: :final_scores, deadline: nil, judged: true}

  # No view, or one it doesn't know: the official app starts the final at the vote.
  defp join_final(s, _view, _info, _index, started),
    do: %{s | phase: :final_vote, question: nil, deadline: started + @vote_ms}

  defp open_question(s, question, started) do
    %{
      s
      | phase: if(question.final, do: :final_question, else: :question),
        question: question,
        deadline: started + s.question_seconds * 1000,
        overtime: false,
        draft: nil,
        judgements: %{},
        judged: false
    }
  end

  defp joined_question(info, index, final?) do
    %{
      index: index,
      text: text(info["questionText"] || info["question"], @max_long_text) || "",
      category: text(info["questionCategory"], @max_text),
      difficulty: difficulty(info["questionDifficulty"]),
      image_url: text(info["questionImgSrc"], @max_long_text),
      final: final?
    }
  end

  defp put_picked(s, picked) when picked in @final_votes, do: put_in(s.final.picked, picked)
  defp put_picked(s, _picked), do: s

  # `{"<wager>": mark}`: the keys are the wagers used.
  defp put_used_wagers(s, %{} = wagers) do
    used =
      for {wager, _mark} <- Enum.take(wagers, @max_index + 1),
          wager = to_int(wager),
          wager in 1..@max_index//1,
          into: s.used_wagers,
          do: wager

    %{s | used_wagers: used}
  end

  defp put_used_wagers(s, _), do: s

  # This player's own answers so far, as `game_connect` lists them for a rejoin
  # (`questions`: `{questionIndex, guessText, wagerAmount, …}`), so each is answered once.
  defp put_own_answers(s, questions) do
    sent =
      for %{"questionIndex" => index} = q <- first(questions, @max_index + 1),
          is_integer(index) and index in 0..@max_index,
          into: s.sent,
          do:
            {index,
             %{text: text(q["guessText"], @max_text) || "", wager: integer(q["wagerAmount"]) || 0}}

    %{s | sent: sent}
  end

  # The lobby again, of the same game: `next_game` after the final, `go_to_lobby` from the
  # host. Both carry the pack, and the pack votes as they stand.
  defp to_lobby(s, payload) do
    payload = if is_map(payload), do: payload, else: %{}

    s
    |> put_pack(payload["gamePack"])
    |> put_pack_votes(payload["packVotes"])
    |> new_game()
    |> Map.merge(%{phase: :lobby, rounds: []})
  end

  defp notice(s, kind, now),
    do: %{
      s
      | notice: %{kind: kind, level: "info", title: nil, message: nil, until: now + @notice_ms}
    }

  defp blank?(nil), do: true
  defp blank?(text), do: String.trim(text) == ""

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
        final: %{votes: %{}, picked: nil, wagers: %{}, vote: nil, wager: nil},
        ratings: %{},
        reports: %{},
        used_wagers: MapSet.new(),
        next_game_code: nil,
        countdown: nil
    }
  end

  # One GiftedChat message from Sporcle: `{_id, text, createdAt, user: {_id, peerId, name,
  # …}, image, system}`. `user._id` is the sender's Sporcle id, `name` the name the
  # official app shows. A message with neither words nor a picture is dropped. `at` is
  # when it arrived, or for history, when it says it was written (never later than now).
  defp chat_message(%{} = m, fallback_at, now) do
    user = if is_map(m["user"]), do: m["user"], else: %{}
    words = TriviaRelay.Text.clean(m["text"], @chat_in_max)
    image = image_url(m["image"])

    if words == "" and image == nil do
      nil
    else
      %{
        id: message_id(m["_id"]),
        player_id: text(user["_id"], @max_text),
        name: clean_name(user["name"]),
        text: words,
        image_url: image,
        system: m["system"] == true,
        at: min(created_at(m["createdAt"]) || fallback_at, now)
      }
    end
  end

  defp chat_message(_m, _fallback_at, _now), do: nil

  defp message_id(id) when is_binary(id) and id != "", do: text(id, 64)
  defp message_id(id) when int?(id), do: Integer.to_string(id)
  defp message_id(_id), do: nil

  # Only a picture on the web, as the official app's keyboard sends one (a GIF's link).
  defp image_url("https://" <> _ = url) when byte_size(url) <= @max_long_text, do: url
  defp image_url(_url), do: nil

  defp created_at(ms) when int?(ms) and ms > 0, do: ms

  defp created_at(iso) when is_binary(iso) and byte_size(iso) <= 40 do
    case DateTime.from_iso8601(iso) do
      {:ok, at, _offset} -> DateTime.to_unix(at, :millisecond)
      _ -> nil
    end
  end

  defp created_at(_), do: nil

  defp clean_name(name) do
    case TriviaRelay.Text.clean(name, @max_name) do
      "" -> nil
      name -> name
    end
  end

  # A new message at the end, once (Sporcle may send one both as `chat_message` and as
  # `last_chat_message`). Another player's counts as unread while the chat is closed here.
  defp add_chat(s, m) do
    {m, seq} = with_id(m, s.chat.seq)
    chat = %{s.chat | seq: seq}

    if Enum.any?(chat.messages, &(&1.id == m.id)) do
      %{s | chat: chat}
    else
      unread =
        if chat.open or m.player_id == s.me, do: chat.unread, else: min(chat.unread + 1, 999)

      messages = Enum.take(chat.messages ++ [m], -@chat_history)
      typing = if m.player_id, do: Map.delete(chat.typing, m.player_id), else: chat.typing
      %{s | chat: %{chat | messages: messages, unread: unread, typing: typing}}
    end
  end

  # A page of history (newest first) merged into what the seat has, by id, in time order.
  defp put_chat_page(s, messages, now) do
    {page, seq} =
      messages
      |> Enum.take(@chat_history)
      |> Enum.reverse()
      |> Enum.map(&chat_message(&1, now, now))
      |> Enum.reject(&is_nil/1)
      |> Enum.map_reduce(s.chat.seq, &with_id/2)

    %{s | chat: %{s.chat | seq: seq, messages: merge_chat(page, s.chat.messages)}}
  end

  defp merge_chat(earlier, later) do
    (earlier ++ later)
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(& &1.at)
    |> Enum.take(-@chat_history)
  end

  defp with_id(%{id: nil} = m, seq), do: {%{m | id: "relay-#{seq + 1}"}, seq + 1}
  defp with_id(m, seq), do: {m, seq}

  defp recently_reacted?(%{reactions: %{received: []}}, _now), do: false

  defp recently_reacted?(s, now),
    do: now - List.last(s.reactions.received).at < @reaction_play_gap_ms

  defp add_reaction(s, from, type, now) do
    id = s.reactions.seq + 1
    reaction = %{id: id, from: from, type: type, at: now, until: now + @reaction_ms}

    received =
      s.reactions.received
      |> Enum.filter(&(&1.until > now))
      |> Kernel.++([reaction])
      |> Enum.take(-@max_reactions)

    %{s | reactions: %{s.reactions | received: received, seq: id}}
  end

  defp u2u_counts(counts) do
    recent =
      for entry <- first(counts["stream"], 1_000),
          is_binary(entry),
          [type | _] = String.split(entry, "-", parts: 2),
          type in @reaction_types,
          do: type

    %{
      total: max(integer(counts["total"]) || 0, 0),
      recent: Enum.take(recent, -@recent_reactions)
    }
  end

  # `{packId: {gamePack, voters: [playerId]}}`, as `pack_votes`, `game_connect` and
  # `next_game` carry it. A pack the app couldn't show is left out.
  defp put_pack_votes(s, %{} = votes) do
    votes =
      for {_key, %{"gamePack" => %{} = game_pack} = vote} <- Enum.take(votes, @max_voted_packs),
          %{pack: pack} = put_pack(%{s | pack: nil}, game_pack),
          pack != nil,
          into: %{} do
        voters =
          for voter <- first(vote["voters"], @max_players),
              is_binary(voter),
              do: text(voter, @max_text)

        {pack.id, %{game_pack: game_pack, pack: pack, voters: Enum.uniq(voters)}}
      end

    %{s | pack_votes: votes}
  end

  defp put_pack_votes(s, _), do: s

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
        ready_for_next_game: p["readyForNextGame"] == true,
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
