defmodule TriviaRelay.Spike.Session do
  @moduledoc """
  One player in one Sporcle game, driven from the spike console.

  It creates or joins the game over REST, owns the `Upstream` connection, prints
  what arrives, and turns console commands into game messages. `drop`, `rejoin`
  and `reuse` are the experiments: what does Sporcle do when a player's socket
  goes away, and what does it take to get the same seat back?
  """

  use GenServer

  alias TriviaRelay.Sporcle.{Api, FrameLog, Identity, Upstream}

  @help """
  ready              tell the lobby you are ready (player_update readyForGame)
  start              start the game (host)
  a <text>           answer the current question: wager 0, or your final wager in the final
  w <n> <text>       answer with a wager of n
  reveal             show everyone the answer (host: advance_all GameShowAnswer)
  judge <peer> y|n   mark a player's answer (host; sends the whole map, as the app does)
  submit             submit the judgements (host: judge_answers)
  next               next question (host; into the final round after the last one)
  view <name>        advance_all to a view (host, final round: voteCategory, showAnswer, score)
  options K=V ...    edit_options in the lobby (host), e.g. QUESTIONS_PER_GAME=5
  play_again         play again after the final scores (host)
  vote easy|medium|hard  final-round vote
  fwager <n>         final-round wager
  send <event> [json]  any other game message
  drop               cut the socket with no close, like a phone losing signal
  close              close the socket properly
  rejoin             joinGame again with the same code, then connect (new player session)
  reuse              connect again with the previous player session
  status             what this console knows
  help, quit
  """

  def help, do: @help

  @doc """
  Options: `:role` (`:host` or `:join`), `:cred`, `:log`, and `:pack` plus
  `:options` for a host or `:code` for a joiner.
  """
  def start_link(opts), do: GenServer.start_link(__MODULE__, Map.new(opts))

  def command(pid, line), do: GenServer.call(pid, {:command, line}, 30_000)

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)

    state =
      %{code: nil, pack: nil, options: %{}}
      |> Map.merge(opts)
      |> Map.merge(%{
        upstream: nil,
        label: nil,
        conn_no: 0,
        qi: nil,
        judgements: %{},
        per_game: nil,
        final_qi: nil,
        final_wager: nil,
        session: nil,
        t0: now()
      })

    case open(state) do
      {:ok, state} -> {:ok, state}
      {:error, reason} -> {:stop, reason}
    end
  end

  defp open(%{role: :host} = s) do
    with {:ok, pack} <- Api.get_pack(s.cred, s.pack),
         {:ok, game} <- Api.create_game(s.cred, pack, s.options) do
      say(
        s,
        "created game #{game["gameCode"]} of \"#{pack["name"]}\" (#{pack["num_questions"]} questions)"
      )

      FrameLog.write(s.log, "rest", "ctl", %{kind: "create_game", response: redact(game)})
      {:ok, connect(%{s | code: game["gameCode"]}, game["playerSession"])}
    end
  end

  defp open(%{role: :join} = s) do
    with {:ok, joined} <- join(s), do: {:ok, connect(s, joined["playerSession"])}
  end

  defp join(s) do
    result = Api.join_game(s.cred, s.code)

    FrameLog.write(s.log, "rest", "ctl", %{
      kind: "join_game",
      code: s.code,
      result: redact(result)
    })

    result
  end

  defp connect(s, session) do
    label = "c#{s.conn_no + 1}"

    {:ok, pid} =
      Upstream.start_link(
        owner: self(),
        log: s.log,
        label: label,
        session: session,
        player: Identity.player(s.cred, s.role == :host, s.options)
      )

    say(s, "#{label}: connecting to #{session["DnsName"]}:#{session["Port"]}")
    %{s | upstream: pid, label: label, conn_no: s.conn_no + 1, session: session}
  end

  @impl true
  def handle_call({:command, line}, _from, s) do
    {reply, s} = run(String.split(String.trim(line), " ", parts: 2), s)
    {:reply, reply, s}
  end

  defp run([""], s), do: {:ok, s}
  defp run(["help"], s), do: {{:print, @help}, s}
  defp run(["status"], s), do: {{:print, status(s)}, s}
  defp run(["ready"], s), do: game(s, "player_update", %{readyForGame: true})
  defp run(["start"], s), do: game(s, "start_game", :none)
  defp run(["a", text], s), do: answer(s, default_wager(s), text)

  defp run(["w", rest], s) do
    with [n, text] <- String.split(rest, " ", parts: 2),
         {wager, ""} <- Integer.parse(n) do
      answer(s, wager, text)
    else
      _ -> {{:error, "usage: w <n> <text>"}, s}
    end
  end

  defp run(["reveal"], s), do: game(s, "advance_all", %{currentView: "GameShowAnswer"})
  defp run(["next"], s), do: next(s, s.per_game != nil and s.qi == s.per_game - 1)
  defp run(["play_again"], s), do: game(s, "play_again", :none)
  defp run(["view", view], s), do: game(s, "advance_all", %{currentView: view})

  defp run(["judge", rest], %{qi: qi} = s) when qi != nil do
    case String.split(rest) do
      [peer, verdict] when verdict in ~w(y n) ->
        judgements = Map.put(s.judgements, peer, verdict == "y")

        {reply, s} =
          game(s, "judgement_update", %{questionIndex: qi, playerJudgements: judgements})

        {reply, %{s | judgements: judgements}}

      _ ->
        {{:error, "usage: judge <peer> y|n"}, s}
    end
  end

  defp run(["submit"], %{qi: qi} = s) when qi != nil,
    do: game(s, "judge_answers", %{questionIndex: qi, playerJudgements: s.judgements})

  defp run(["options", rest], s) do
    options =
      for pair <- String.split(rest), [k, v] = String.split(pair, "=", parts: 2), into: %{} do
        {k, option_value(v)}
      end

    game(s, "edit_options", options)
  end

  defp run(["vote", type], s) when type in ~w(easy medium hard),
    do: game(s, "vote_final_round", %{voteType: type})

  defp run(["fwager", n], s) do
    case Integer.parse(n) do
      {wager, ""} ->
        {reply, s} = game(s, "submit_final_wager", %{wagerAmount: wager})
        {reply, if(reply == :ok, do: %{s | final_wager: wager}, else: s)}

      _ ->
        {{:error, "usage: fwager <n>"}, s}
    end
  end

  defp run(["send", rest], s) do
    case String.split(rest, " ", parts: 2) do
      [event] ->
        game(s, event, :none)

      [event, json] ->
        case Jason.decode(json) do
          {:ok, payload} -> game(s, event, payload)
          {:error, _} -> {{:error, "payload is not JSON"}, s}
        end
    end
  end

  defp run(["drop"], s), do: on_upstream(s, &Upstream.drop/1)
  defp run(["close"], s), do: on_upstream(s, &Upstream.close/1)

  defp run(["rejoin"], %{upstream: nil} = s) do
    case join(s) do
      {:ok, joined} -> {:ok, connect(s, joined["playerSession"])}
      {:error, reason} -> {{:error, "joinGame: #{inspect(reason)}"}, s}
    end
  end

  defp run(["reuse"], %{upstream: nil, session: session} = s) when session != nil,
    do: {:ok, connect(s, session)}

  defp run([cmd | _], %{upstream: pid} = s) when cmd in ~w(rejoin reuse) and pid != nil,
    do: {{:error, "still connected; drop or close first"}, s}

  defp run(_, s), do: {{:error, "unknown command; try help"}, s}

  defp answer(%{qi: nil} = s, _, _), do: {{:error, "no question yet"}, s}

  defp answer(s, wager, text),
    do: game(s, "answer_question", %{questionIndex: s.qi, wagerAmount: wager, guessText: text})

  # The server scores the wager an answer carries, in the final round too: an
  # answer sent without the final wager stakes nothing.
  defp default_wager(%{qi: qi, final_qi: qi, final_wager: wager}) when is_integer(wager),
    do: wager

  defp default_wager(_), do: 0

  defp next(%{qi: nil} = s, _), do: {{:error, "no question yet"}, s}
  defp next(s, final?), do: game(s, "next_question", %{questionIndex: s.qi, toFinalRound: final?})

  defp game(%{upstream: nil} = s, _, _), do: {{:error, "not connected"}, s}
  defp game(s, event, payload), do: {Upstream.send_event(s.upstream, event, payload), s}

  defp on_upstream(%{upstream: nil} = s, _), do: {{:error, "not connected"}, s}
  defp on_upstream(s, fun), do: {fun.(s.upstream), s}

  @impl true
  def handle_info({:upstream, label, :connected}, s) do
    say(s, "#{label}: logged in; `ready` when you want to be ready")
    {:noreply, s}
  end

  def handle_info({:upstream, label, {:event, event, payload}}, s) do
    say(s, "#{label} <- " <> describe(event, payload))
    {:noreply, track(s, event, payload)}
  end

  def handle_info({:upstream, label, {:frame, fields}}, s) do
    say(s, "#{label} <- (non-game frame) #{inspect(fields, limit: 12, printable_limit: 80)}")
    {:noreply, s}
  end

  def handle_info({:upstream, label, {:closed, reason}}, %{label: label} = s) do
    say(s, "#{label}: closed (#{inspect(reason)}); `rejoin` or `reuse` to come back")
    {:noreply, %{s | upstream: nil}}
  end

  def handle_info({:upstream, label, {:closed, reason}}, s) do
    say(s, "#{label}: closed (#{inspect(reason)})")
    {:noreply, s}
  end

  def handle_info({:EXIT, pid, reason}, %{upstream: pid} = s) when reason != :normal do
    say(s, "upstream crashed: #{inspect(reason)}")
    {:noreply, %{s | upstream: nil}}
  end

  def handle_info({:EXIT, _pid, _reason}, s), do: {:noreply, s}

  defp track(s, "game_question", %{"questionIndex" => qi}), do: %{s | qi: qi, judgements: %{}}
  defp track(s, "list_answers", %{"questionIndex" => qi}), do: %{s | qi: qi}

  defp track(s, "judgement_update", %{"playerJudgements" => judgements}),
    do: %{s | judgements: judgements}

  defp track(s, "game_info", %{"gameOptions" => %{"QUESTIONS_PER_GAME" => n}} = info) do
    say(s, "options now #{inspect(info["gameOptions"])}")
    %{s | per_game: n}
  end

  defp track(s, "advance_all", %{"currentView" => "CAST_WAGER", "questionIndex" => qi}),
    do: %{s | final_qi: qi}

  defp track(s, _, _), do: s

  defp describe("game_question", q) do
    "game_question Q#{q["questionIndex"]} [#{q["questionCategory"]}] #{q["question"]}\n" <>
      "    keys: #{q |> Map.keys() |> Enum.sort() |> Enum.join(", ")}"
  end

  defp describe("list_answers", a) do
    guesses =
      for p <- a["allPlayerAnswers"] || [] do
        "    peer #{p["peerId"]}: #{inspect(p["guessText"])} correct=#{p["correct"]} score=#{p["score"]} wager=#{p["wagerAmount"]}"
      end

    Enum.join(
      ["list_answers Q#{a["questionIndex"]} answer: #{inspect(a["answer"])}" | guesses],
      "\n"
    )
  end

  defp describe("game_info", %{"allRounds" => rounds} = info) do
    percents = Enum.map_join(rounds, " ", &"Q#{&1["questionIndex"]}:#{&1["percent"]}%")
    "game_info (game start) #{inspect(info["gameOptions"])} rounds #{percents}"
  end

  defp describe("game_info", info) do
    players =
      for p <- info["allPlayers"] || [] do
        "    peer #{p["peerId"]} #{p["teamName"]} #{p["playerId"]}#{if p["isHost"], do: " (host)"}" <>
          " connected=#{inspect(p["connected"])}"
      end

    Enum.join(
      [
        "game_info, #{length(players)} players, keys: #{info |> Map.keys() |> Enum.join(", ")}"
        | players
      ],
      "\n"
    )
  end

  defp describe(event, payload), do: "#{event} #{truncate(Jason.encode!(payload), 240)}"

  defp status(s) do
    """
    role #{s.role}, game #{s.code}, #{inspect(s.cred)}
    connection #{if s.upstream, do: "c#{s.conn_no} open", else: "none"}, current question #{inspect(s.qi)}
    player session #{s.session && s.session["PlayerSessionId"]}
    log #{FrameLog.path(s.log)}
    """
  end

  # The token is the player's, and has no business in a log.
  defp redact({:error, {:http, status, body}}), do: %{error: status, body: redact(body)}
  defp redact({:error, e}), do: %{error: inspect(e)}
  defp redact({:ok, body}), do: redact(body)
  defp redact(map) when is_map(map), do: Map.drop(map, ["token"])
  defp redact(other), do: other

  defp option_value("true"), do: true
  defp option_value("false"), do: false

  defp option_value(v) do
    case Integer.parse(v) do
      {n, ""} -> n
      _ -> v
    end
  end

  defp truncate(text, n) do
    if String.length(text) <= n, do: text, else: String.slice(text, 0, n) <> "…"
  end

  defp say(s, text) do
    secs = :erlang.float_to_binary((now() - s.t0) / 1000, decimals: 1)
    IO.puts("[+#{secs}s] #{text}")
  end

  defp now, do: System.monotonic_time(:millisecond)
end
