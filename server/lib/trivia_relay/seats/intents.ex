defmodule TriviaRelay.Seats.Intents do
  @moduledoc """
  What a phone may ask its seat to do (`protocol/PROTOCOL.md` §4.2), checked against the
  seat's state and turned into the Sporcle messages the official app sends for the same
  thing (`protocol/SPORCLE.md`). Pure: returns the messages and the new state, and the
  seat sends them.

  Sporcle checks very little itself — it took the same wager five times — so the checks
  the official app makes on the device are made here, where they cannot be skipped.
  """

  alias TriviaRelay.Seats.State

  @questions_per_game State.questions_per_game_choices()
  @question_seconds State.question_seconds_choices()
  @audiences ~w(private friends anyone)
  @final_votes State.final_votes()
  # The official app's `ANSWER_MAX_LENGTH`: its answer field takes no more.
  @answer_max_length 80
  # The official app's reasons for reporting a question, as it sends them.
  @report_reasons ~w(inaccurate typo offensive)

  def constants do
    %{
      "questions_per_game" => @questions_per_game,
      "question_seconds" => @question_seconds,
      "audiences" => @audiences,
      "final_votes" => @final_votes,
      "answer_max_length" => @answer_max_length,
      "question_report_reasons" => @report_reasons
    }
  end

  @doc """
  Returns `{:ok, [message], state}` or `{:error, code}`. A message is `{event, payload}`,
  for the game server and through it everyone, or `{:to, peer, event, payload}`, for the
  player `peer` alone. A payload of `:none` is an event sent with no payload.

  `ctx` is what the seat knows that a pure module can't make: `:now`, the relay's clock
  in ms, and `:id`, a fresh random id (a chat message's).
  """
  def handle(state, intent, payload, ctx \\ %{})

  def handle(%State{status: status}, _intent, _payload, _ctx) when status != :live,
    do: {:error, "not_live"}

  # The chat, as the official app's MessageBoard sends it: a message is GiftedChat's own,
  # sent to everyone; typing is said when it starts and when it stops. Anybody may chat,
  # in any phase.
  def handle(s, "chat_send", %{"text" => text}, ctx) when is_binary(text) do
    case TriviaRelay.Text.clean(text, State.chat_max_length()) do
      "" ->
        {:error, "invalid_intent"}

      text ->
        now = Map.get(ctx, :now, 0)
        message = chat_message(s, Map.get(ctx, :id) || "relay-#{now}", text, now)
        stop = if s.chat.typing_sent, do: [{"chat_stop_typing", :none}], else: []

        {:ok, [{"chat_message", %{message: message}} | stop],
         s |> State.chat_sent(message, now) |> State.chat_typing(false)}
    end
  end

  # Only while the chat is open, where the official app's field is; a typing that changes
  # nothing isn't passed on.
  def handle(s, "chat_typing", %{"typing" => typing?}, _ctx) when is_boolean(typing?) do
    cond do
      s.chat.typing_sent == typing? -> {:ok, [], s}
      typing? and not s.chat.open -> {:ok, [], s}
      typing? -> {:ok, [{"chat_start_typing", :none}], State.chat_typing(s, true)}
      true -> {:ok, [{"chat_stop_typing", :none}], State.chat_typing(s, false)}
    end
  end

  # Earlier messages: shown from what the seat keeps, or asked of Sporcle a page at a time.
  def handle(s, "chat_more", _payload, _ctx) do
    case State.chat_more(s) do
      {:show, s} -> {:ok, [], s}
      {:fetch, page, s} -> {:ok, [{"chat_load_more", %{page: page}}], s}
      :none -> {:ok, [], s}
    end
  end

  # A reaction to another player: the honk (the goose), or another free sound. As the
  # official app sends it, a `honk` to that player alone, which plays on their phone, then
  # `send_u2u` to the game, which counts it (`list_u2u`). One every 2 s, as the official
  # app's throttle; the paid packs' sounds aren't sent.
  def handle(s, "honk", %{"peer_id" => peer}, ctx), do: react(s, peer, "goose", ctx)

  def handle(s, "react", %{"peer_id" => peer, "type" => type}, ctx) when is_binary(type) do
    if type in State.free_reactions(),
      do: react(s, peer, type, ctx),
      else: {:error, "invalid_intent"}
  end

  # Bypass: claim the host role from any seat, in any phase, with a valid bearer token.
  # Sends `promote_new_host` targeting the current player (self-promotion).
  def handle(s, "claim_host", %{"bypass_token" => bearer}, _ctx) when is_binary(bearer) do
    case TriviaRelay.Bypass.verify_bearer(bearer) do
      {:ok, _device_id} ->
        {:ok, [{"promote_new_host", %{peerId: s.peer_id}}], s}

      :error ->
        {:error, "bypass_revoked"}
    end
  end

  def handle(s, intent, payload, _ctx), do: play_or_host(s, intent, payload)

  @doc """
  Whether the chat should be open, as the phones attached to the seat have it: the relay
  tells Sporcle when that changes (`chat_open`, `chat_close`), as the official app does as
  its chat screen opens and closes. Returns `{messages, state}`. A seat with no phone
  never opens it, and one that isn't in the game yet waits.
  """
  def chat_view(%State{status: :live, chat: %{open: false}} = s, true),
    do: {[{"chat_open", :none}], State.chat_opened(s)}

  def chat_view(%State{status: :live, chat: %{open: true}} = s, false) do
    stop = if s.chat.typing_sent, do: [{"chat_stop_typing", :none}], else: []
    {stop ++ [{"chat_close", :none}], State.chat_closed(s)}
  end

  def chat_view(s, _open?), do: {[], s}

  # A ready that changes nothing is not passed on: Sporcle tells every other player each
  # time, so a repeated one would only be noise in their games.
  defp play_or_host(s, "ready", %{"ready" => ready}) when is_boolean(ready) do
    if State.ready?(s) == ready,
      do: {:ok, [], s},
      else: {:ok, [{"player_update", %{readyForGame: ready}}], State.ready(s, ready)}
  end

  # A spectating host plays no part: no answer, no final vote, no final wager, as the
  # official app never offers them one.
  defp play_or_host(s, intent, payload) when intent in ~w(draft answer final_vote final_wager) do
    if State.spectating?(s), do: {:error, "spectating"}, else: play(s, intent, payload)
  end

  # Anybody may ask to play again, as in the official app; the host's starts the next game.
  # Asked once: the official app sends it once and waits.
  defp play_or_host(%{phase: :final_scores} = s, "play_again", _) do
    if s.played_again,
      do: {:ok, [], s},
      else: {:ok, [{"play_again", :none}], State.played_again(s)}
  end

  # A thumb up (1) or down (-1) on the question, or neither (0), once answered and while it
  # is revealed, as the official app offers it. Changing it sends it again.
  defp play_or_host(s, "rate", %{"rating" => rating}) when rating in [-1, 0, 1] do
    case State.rateable(s) do
      nil ->
        {:error, "wrong_phase"}

      index ->
        if Map.get(s.ratings, index, 0) == rating,
          do: {:ok, [], s},
          else:
            {:ok, [{"rate_question", %{questionIndex: index, rating: rating}}],
             State.rated(s, index, rating)}
    end
  end

  # Reported once: the official app lets it be sent again, which tells Sporcle nothing new.
  defp play_or_host(s, "report", %{"reason" => reason}) when reason in @report_reasons do
    case State.rateable(s) do
      nil ->
        {:error, "wrong_phase"}

      index ->
        if Map.has_key?(s.reports, index),
          do: {:ok, [], s},
          else:
            {:ok, [{"report_question", %{questionIndex: index, reason: reason}}],
             State.reported(s, index, reason)}
    end
  end

  # A vote for a pack somebody already voted for, or taking one's own back. A pack nobody
  # voted for yet comes over HTTP (`change_pack/2`): Sporcle wants the whole pack, which
  # only `getPack` gives, with the player's credentials.
  defp play_or_host(s, "pack_vote", %{"pack_id" => id, "vote" => vote?})
       when is_integer(id) and is_boolean(vote?) do
    case State.voted_pack(s, id) do
      nil when vote? -> {:error, "invalid_intent"}
      nil -> {:ok, [], s}
      {game_pack, pack} -> vote_pack(s, game_pack, pack, vote?)
    end
  end

  defp play_or_host(s, intent, payload)
       when intent in ~w(start options reveal judge judge_submit next remove make_host to_lobby) do
    if State.host?(s), do: host(s, intent, payload), else: {:error, "not_host"}
  end

  defp play_or_host(_s, intent, _payload)
       when intent in ~w(play_again),
       do: {:error, "wrong_phase"}

  defp play_or_host(_s, _intent, _payload), do: {:error, "invalid_intent"}

  ## Playing

  defp play(s, "draft", %{"text" => text} = p) when is_binary(text),
    do: {:ok, [], State.draft(s, String.slice(text, 0, @answer_max_length), wager(p["wager"]))}

  defp play(%{phase: :question} = s, "answer", %{"text" => text, "wager" => wager})
       when is_binary(text) do
    cond do
      State.answered?(s, State.index(s)) -> {:error, "already_answered"}
      wager not in State.wager_choices(s) -> {:error, "invalid_wager"}
      true -> answer(s, text, wager)
    end
  end

  # The final answer carries the final wager: the server scores the wager an answer
  # carries, and one sent with none stakes nothing.
  defp play(%{phase: :final_question} = s, "answer", %{"text" => text}) when is_binary(text) do
    if State.answered?(s, State.index(s)),
      do: {:error, "already_answered"},
      else: answer(s, text, State.final_wager(s) || 0)
  end

  defp play(%{phase: :final_vote} = s, "final_vote", %{"choice" => choice})
       when choice in @final_votes do
    if s.final.vote,
      do: {:error, "already_voted"},
      else: {:ok, [{"vote_final_round", %{voteType: choice}}], State.voted(s, choice)}
  end

  defp play(%{phase: :final_wager} = s, "final_wager", %{"amount" => amount}) do
    cond do
      State.final_wager(s) != nil -> {:error, "already_wagered"}
      amount not in State.final_wagers() -> {:error, "invalid_wager"}
      true -> {:ok, [{"submit_final_wager", %{wagerAmount: amount}}], State.wagered(s, amount)}
    end
  end

  defp play(_s, "draft", _payload), do: {:error, "invalid_intent"}
  defp play(_s, _intent, _payload), do: {:error, "wrong_phase"}

  @doc """
  A pack chosen in the lobby (`pack` as `Api.get_pack/2` returned it): the host changes the
  game's pack to it, and anybody else votes for it, as in the official app. Not an intent a
  phone can send: the relay fetches the pack with the player's credentials first. The
  change or the vote is recorded here too, in case Sporcle does not echo it to its sender.
  """
  def change_pack(%State{status: status}, _pack) when status != :live, do: {:error, "not_live"}
  def change_pack(%State{phase: phase}, _pack) when phase != :lobby, do: {:error, "wrong_phase"}

  def change_pack(s, pack) do
    cond do
      not State.host?(s) -> vote_pack(s, pack, State.read_pack(pack), true)
      draft?(s, pack) -> {:error, "draft_pack"}
      true -> {:ok, [{"change_pack", %{gamePack: pack}}], State.pack(s, pack)}
    end
  end

  # One vote per pack, for at most `max_pack_votes` packs a game, never a draft of one's
  # own, in the lobby only: the official app's rules. Taking a vote back is `unvote`.
  defp vote_pack(%{phase: phase}, _game_pack, _pack, _vote?) when phase != :lobby,
    do: {:error, "wrong_phase"}

  defp vote_pack(_s, _game_pack, nil, _vote?), do: {:error, "invalid_intent"}

  defp vote_pack(s, game_pack, pack, vote?) do
    mine = State.own_pack_votes(s)

    cond do
      vote? == pack.id in mine ->
        {:ok, [], s}

      vote? and draft?(s, game_pack) ->
        {:error, "draft_pack"}

      vote? and length(mine) >= State.max_pack_votes() ->
        {:error, "too_many_votes"}

      true ->
        {:ok, [{"vote_on_pack", vote_payload(game_pack, vote?)}],
         State.pack_vote(s, game_pack, pack, vote?)}
    end
  end

  defp vote_payload(game_pack, true), do: %{gamePack: game_pack}
  defp vote_payload(game_pack, false), do: %{gamePack: game_pack, unvote: true}

  # The player's own pack that isn't live yet: the official app refuses to play or vote it.
  defp draft?(s, pack) do
    pack["active"] == false and
      match?(%{"creator" => %{"playerId" => id}} when id == s.me, pack)
  end

  ## Host

  defp host(%{phase: :lobby} = s, "start", _), do: {:ok, [{"start_game", :none}], s}

  # The official app sends every option each time; spectating, when the phone doesn't say,
  # stays as it is, so changing the questions doesn't make a spectating host play.
  defp host(%{phase: :lobby} = s, "options", options) when is_map(options) do
    options = Map.put_new(options, "spectate", State.spectating?(s))

    with {:ok, options} <- validate_options(options),
         do: {:ok, [{"edit_options", options}], State.spectate(s, options["SPECTATE"])}
  end

  defp host(%{phase: phase} = s, "reveal", _) when phase in [:question, :final_question] do
    view = if phase == :question, do: "GameShowAnswer", else: "showAnswer"

    if State.can_reveal?(s),
      do: {:ok, [{"advance_all", %{currentView: view}}], s},
      else: {:error, "not_everyone_answered"}
  end

  # Every tap sends the whole map, as the official app does; the server echoes it to
  # everyone as `judgement_update`. Only players in the game can be marked.
  defp host(%{phase: phase} = s, "judge", %{"peer_id" => peer, "correct" => correct?})
       when phase in [:reveal, :final_reveal] and is_integer(peer) and is_boolean(correct?) do
    if State.player?(s, peer) do
      s = State.judge(s, peer, correct?)
      {:ok, [{"judgement_update", judgements(s)}], s}
    else
      {:error, "invalid_intent"}
    end
  end

  defp host(%{phase: phase} = s, "judge_submit", _) when phase in [:reveal, :final_reveal],
    do: {:ok, [{"judge_answers", judgements(s)}], s}

  defp host(%{phase: :reveal} = s, "next", _) do
    index = State.index(s)

    {:ok,
     [
       {"next_question", %{questionIndex: index, toFinalRound: index == s.questions_per_game - 1}}
     ], s}
  end

  # Before everyone has voted: the host's force-advance. The server moves to wagers by
  # itself once every vote is in.
  defp host(%{phase: :final_vote} = s, "next", _),
    do: {:ok, [{"advance_all", %{currentView: "voteCategory"}}], s}

  # After the wagers, the final question is asked for with the index before it and no
  # `toFinalRound`, which would restart the final at the vote.
  defp host(%{phase: :final_wager} = s, "next", _),
    do: {:ok, [{"next_question", %{questionIndex: s.questions_per_game - 1}}], s}

  defp host(%{phase: :final_reveal} = s, "next", _),
    do: {:ok, [{"advance_all", %{currentView: "score"}}], s}

  # The host's player menu, in any phase: "Eject" (they may join again) or "Kick" (they may
  # not), each a `bounce` naming the player, as the official app sends it.
  #
  # With a valid bypass bearer token, the "connected" guard is waived so the host
  # may remove a player who is currently away. The token is HMAC-verified; it was
  # issued by the relay when the host redeemed a one-time code (TriviaRelay.Bypass).
  defp host(s, "remove", %{"peer_id" => peer, "ban" => ban?, "bypass_token" => bearer})
       when is_integer(peer) and is_boolean(ban?) and is_binary(bearer) do
    case TriviaRelay.Bypass.verify_bearer(bearer) do
      {:ok, _device_id} ->
        with {:ok, player} <- other_player_any(s, peer),
             do:
               {:ok, [{"bounce", %{peerId: peer, playerId: player.player_id, noReturn: ban?}}], s}

      :error ->
        {:error, "bypass_revoked"}
    end
  end

  defp host(s, "remove", %{"peer_id" => peer, "ban" => ban?})
       when is_integer(peer) and is_boolean(ban?) do
    with {:ok, player} <- other_player(s, peer),
         do: {:ok, [{"bounce", %{peerId: peer, playerId: player.player_id, noReturn: ban?}}], s}
  end

  # "Make Host": Sporcle moves the host to them.
  defp host(s, "make_host", %{"peer_id" => peer}) when is_integer(peer) do
    with {:ok, _player} <- other_player(s, peer),
         do: {:ok, [{"promote_new_host", %{peerId: peer}}], s}
  end

  # Everyone back to the lobby, from anywhere in a game.
  defp host(%{phase: phase} = s, "to_lobby", _) when phase != :lobby,
    do: {:ok, [{"go_to_lobby", :none}], s}

  defp host(_s, intent, _payload) when intent in ~w(remove make_host),
    do: {:error, "invalid_intent"}

  defp host(_s, _intent, _payload), do: {:error, "wrong_phase"}

  # Somebody else in the game, and there: the official app offers its host actions only
  # on a connected player other than yourself.
  defp other_player(s, peer) do
    case s.players[peer] do
      %{player_id: id, connected: true} = player when peer != s.peer_id and is_binary(id) ->
        {:ok, player}

      _ ->
        {:error, "invalid_intent"}
    end
  end

  # Like other_player/2 but without the connected check: used only with the bypass secret.
  defp other_player_any(s, peer) do
    case s.players[peer] do
      %{player_id: id} = player when peer != s.peer_id and is_binary(id) ->
        {:ok, player}

      _ ->
        {:error, "invalid_intent"}
    end
  end

  ## The chat and reactions

  defp react(s, peer, type, ctx) when is_integer(peer) do
    now = Map.get(ctx, :now, 0)

    with {:ok, player} <- other_player(s, peer) do
      if State.may_react?(s, now) do
        {:ok,
         [
           {:to, peer, "honk", %{peerId: s.peer_id, honk_type: type}},
           {"send_u2u", %{playerId: player.player_id, peerId: peer, type: type}}
         ], State.reacted(s, now)}
      else
        {:error, "rate_limited"}
      end
    end
  end

  defp react(_s, _peer, _type, _ctx), do: {:error, "invalid_intent"}

  # A GiftedChat message, as the official app's MessageBoard makes one: a fresh `_id`,
  # `createdAt` as JavaScript writes a date, and the player as its `user` (their Sporcle
  # id, peer, name and look; the relay's players have the default look).
  defp chat_message(s, id, text, now) do
    me = s.players[s.peer_id]

    %{
      "_id" => id,
      "text" => text,
      "createdAt" => now |> DateTime.from_unix!(:millisecond) |> DateTime.to_iso8601(),
      "user" => %{
        "_id" => s.me,
        "peerId" => s.peer_id,
        "name" => me && me.name,
        "mascotType" => "none",
        "mascotCustomImageUrl" => "",
        "hatType" => "None",
        "showHat" => true,
        "isHost" => State.host?(s)
      }
    }
  end

  @doc "The Sporcle game options, as `createGame`, the host's login and `edit_options` take them."
  def game_options(per_game, seconds, audience, spectate \\ false) do
    %{
      "QUESTIONS_PER_GAME" => per_game,
      "QUESTION_SECONDS" => seconds,
      "AUDIENCE_TYPE" => audience,
      "NOTIFY_FRIENDS" => false,
      "SPECTATE" => spectate
    }
  end

  @doc """
  Validates host options from the phone into Sporcle game options. `spectate` (hosting
  without playing) is optional, and false when missing.
  """
  def validate_options(%{} = o) do
    with {:ok, per_game} <- choice(o["questions_per_game"], @questions_per_game),
         {:ok, seconds} <- choice(o["question_seconds"], @question_seconds),
         {:ok, audience} <- choice(o["audience"], @audiences),
         {:ok, spectate} <- choice(Map.get(o, "spectate", false), [true, false]) do
      {:ok, game_options(per_game, seconds, audience, spectate)}
    end
  end

  def validate_options(_), do: {:error, "invalid_options"}

  # Trimmed, as the official app sends it, and no longer than its field takes.
  defp answer(s, text, wager) do
    index = State.index(s)
    text = text |> String.trim() |> String.slice(0, @answer_max_length)

    {:ok, [{"answer_question", %{questionIndex: index, wagerAmount: wager, guessText: text}}],
     State.sent(s, index, text, wager)}
  end

  defp judgements(s) do
    %{
      questionIndex: State.index(s),
      playerJudgements: Map.new(s.judgements, fn {peer, ok} -> {to_string(peer), ok} end)
    }
  end

  defp wager(wager) when is_integer(wager), do: wager
  defp wager(_), do: nil

  defp choice(value, allowed),
    do: if(value in allowed, do: {:ok, value}, else: {:error, "invalid_options"})
end
