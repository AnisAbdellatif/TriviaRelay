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

  @questions_per_game [5, 10, 15, 20]
  @question_seconds [15, 30, 45, 60]
  @audiences ~w(private friends anyone)
  @final_votes ~w(easy medium hard)

  def constants do
    %{
      "questions_per_game" => @questions_per_game,
      "question_seconds" => @question_seconds,
      "audiences" => @audiences,
      "final_votes" => @final_votes
    }
  end

  @doc """
  Returns `{:ok, [{event, payload}], state}` or `{:error, code}`. A payload of `:none`
  is an event sent with no payload.
  """
  def handle(%State{status: status}, _intent, _payload) when status != :live,
    do: {:error, "not_live"}

  def handle(s, "ready", %{"ready" => ready}) when is_boolean(ready),
    do: {:ok, [{"player_update", %{readyForGame: ready}}], State.ready(s, ready)}

  def handle(s, "draft", %{"text" => text} = p) when is_binary(text),
    do: {:ok, [], State.draft(s, String.slice(text, 0, 200), p["wager"])}

  def handle(%{phase: :question} = s, "answer", %{"text" => text, "wager" => wager})
      when is_binary(text) do
    cond do
      State.answered?(s, State.index(s)) -> {:error, "already_answered"}
      wager not in State.wager_choices(s) -> {:error, "invalid_wager"}
      true -> answer(s, text, wager)
    end
  end

  # The final answer carries the final wager: the server scores the wager an answer
  # carries, and one sent with none stakes nothing.
  def handle(%{phase: :final_question} = s, "answer", %{"text" => text}) when is_binary(text) do
    if State.answered?(s, State.index(s)),
      do: {:error, "already_answered"},
      else: answer(s, text, s.final.wager || 0)
  end

  def handle(%{phase: :final_vote} = s, "final_vote", %{"choice" => choice})
      when choice in @final_votes do
    if s.final.vote,
      do: {:error, "already_voted"},
      else: {:ok, [{"vote_final_round", %{voteType: choice}}], State.voted(s, choice)}
  end

  def handle(%{phase: :final_wager} = s, "final_wager", %{"amount" => amount}) do
    cond do
      s.final.wager != nil -> {:error, "already_wagered"}
      amount not in State.final_wagers() -> {:error, "invalid_wager"}
      true -> {:ok, [{"submit_final_wager", %{wagerAmount: amount}}], State.wagered(s, amount)}
    end
  end

  # Anybody may ask to play again, as in the official app; the host's starts the next game.
  # Asked once: the official app sends it once and waits.
  def handle(%{phase: :final_scores} = s, "play_again", _) do
    if s.played_again,
      do: {:ok, [], s},
      else: {:ok, [{"play_again", :none}], State.played_again(s)}
  end

  def handle(s, intent, payload)
      when intent in ~w(start options reveal judge judge_submit next) do
    if State.host?(s), do: host(s, intent, payload), else: {:error, "not_host"}
  end

  def handle(_s, intent, _payload)
      when intent in ~w(answer final_vote final_wager play_again),
      do: {:error, "wrong_phase"}

  def handle(_s, _intent, _payload), do: {:error, "invalid_intent"}

  @doc """
  The host changing the lobby's pack to `pack` (as `Api.get_pack/2` returned it). Not an
  intent a phone can send: the relay fetches the pack with the host's credentials first.
  The pack is recorded here too, in case Sporcle does not echo it back to its sender.
  """
  def change_pack(%State{status: status}, _pack) when status != :live, do: {:error, "not_live"}

  def change_pack(s, pack) do
    cond do
      not State.host?(s) -> {:error, "not_host"}
      s.phase != :lobby -> {:error, "wrong_phase"}
      true -> {:ok, [{"change_pack", %{gamePack: pack}}], State.pack(s, pack)}
    end
  end

  ## Host

  defp host(%{phase: :lobby} = s, "start", _), do: {:ok, [{"start_game", :none}], s}

  defp host(%{phase: :lobby} = s, "options", options) do
    with {:ok, options} <- validate_options(options), do: {:ok, [{"edit_options", options}], s}
  end

  defp host(%{phase: phase} = s, "reveal", _) when phase in [:question, :final_question] do
    view = if phase == :question, do: "GameShowAnswer", else: "showAnswer"

    if State.can_reveal?(s),
      do: {:ok, [{"advance_all", %{currentView: view}}], s},
      else: {:error, "not_everyone_answered"}
  end

  # Every tap sends the whole map, as the official app does; the server echoes it to
  # everyone as `judgement_update`.
  defp host(%{phase: phase} = s, "judge", %{"peer_id" => peer, "correct" => correct?})
       when phase in [:reveal, :final_reveal] and is_integer(peer) and is_boolean(correct?) do
    s = State.judge(s, peer, correct?)
    {:ok, [{"judgement_update", judgements(s)}], s}
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

  defp host(_s, _intent, _payload), do: {:error, "wrong_phase"}

  @doc "The Sporcle game options, as `createGame`, the host's login and `edit_options` take them."
  def game_options(per_game, seconds, audience) do
    %{
      "QUESTIONS_PER_GAME" => per_game,
      "QUESTION_SECONDS" => seconds,
      "AUDIENCE_TYPE" => audience,
      "NOTIFY_FRIENDS" => false,
      "SPECTATE" => false
    }
  end

  @doc "Validates host options from the phone into Sporcle game options."
  def validate_options(%{} = o) do
    with {:ok, per_game} <- choice(o["questions_per_game"], @questions_per_game),
         {:ok, seconds} <- choice(o["question_seconds"], @question_seconds),
         {:ok, audience} <- choice(o["audience"], @audiences) do
      {:ok, game_options(per_game, seconds, audience)}
    end
  end

  def validate_options(_), do: {:error, "invalid_options"}

  defp answer(s, text, wager) do
    index = State.index(s)
    text = String.slice(text, 0, 200)

    {:ok, [{"answer_question", %{questionIndex: index, wagerAmount: wager, guessText: text}}],
     State.sent(s, index, text, wager)}
  end

  defp judgements(s) do
    %{
      questionIndex: State.index(s),
      playerJudgements: Map.new(s.judgements, fn {peer, ok} -> {to_string(peer), ok} end)
    }
  end

  defp choice(value, allowed),
    do: if(value in allowed, do: {:ok, value}, else: {:error, "invalid_options"})
end
