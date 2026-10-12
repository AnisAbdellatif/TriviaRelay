defmodule TriviaRelay.SnapshotFixturesTest do
  @moduledoc """
  The snapshots in `protocol/fixtures/snapshots/` are what the relay sends a phone at
  moments of the recorded game, and the app's tests parse the same files: this is
  what holds the two sides to one `state` (PROTOCOL.md §5.1). Regenerate them after
  a deliberate change with `UPDATE_FIXTURES=1 mix test`.
  """

  use ExUnit.Case, async: true

  alias TriviaRelay.{Fixtures, Replay}
  alias TriviaRelay.Seats.{State, View}

  @now 1_790_000_000_000

  defp snapshots do
    %{
      "lobby_host" => Replay.first(&(&1.phase == :lobby and map_size(&1.players) == 2)),
      "question_player" => Replay.fresh(:question, :join),
      "question_host_answered" =>
        Replay.first(&(&1.phase == :question and map_size(&1.answers[0][:entries] || %{}) == 2)),
      "reveal_host" => Replay.fresh(:reveal),
      "reveal_judged_player" => Replay.first(&(&1.phase == :reveal and &1.judged), :join),
      "final_vote_player" => Replay.fresh(:final_vote, :join),
      "final_wager_host" => Replay.fresh(:final_wager),
      # Both have wagered: the player sees their own amount, and only that the host wagered.
      "final_wager_player" =>
        Replay.first(&(&1.phase == :final_wager and map_size(&1.final.wagers) == 2), :join),
      "final_question_player" => Replay.fresh(:final_question, :join),
      "final_scores_host" => Replay.fresh(:final_scores),
      # Since 1.2.
      "lobby_player_votes" => lobby_player_votes(),
      "question_countdown_player" => Replay.fresh(:question, :join),
      "question_spectator_host" => question_spectator_host(),
      "question_rejoined_player" => question_rejoined_player(),
      "reveal_rated_player" => reveal_rated_player(),
      "lobby_notice_player" => lobby_notice_player(),
      "final_scores_left_behind_player" => final_scores_left_behind_player(),
      "lobby_chat_player" => lobby_chat_player(),
      "reveal_reactions_player" => reveal_reactions_player(),
      "question_popper_notice_player" => question_popper_notice_player()
    }
  end

  # The chat: history loaded on opening (the host's message and one from the game), this
  # player's own, then closed, the host writing again (unread) and typing.
  defp lobby_chat_player do
    s = Replay.first(&(&1.phase == :lobby and map_size(&1.players) == 2), :join)
    host = %{"_id" => "sporcle_id//hostPlayer", "peerId" => 1, "name" => "Host"}

    s
    |> State.chat_opened()
    |> State.apply_event(
      "chat_load",
      %{
        "messages" => [
          %{
            "_id" => "m2",
            "text" => "Welcome to the game!",
            "system" => true,
            "createdAt" => 900
          },
          %{"_id" => "m1", "text" => "مرحبا!", "user" => host, "createdAt" => 800}
        ],
        "hasMore" => false
      },
      1_000
    )
    |> State.chat_sent(
      %{"_id" => "m3", "text" => "Hi all", "user" => %{"_id" => "sporcle_id//joinPlayer"}},
      1_100
    )
    |> State.chat_closed()
    |> State.apply_event(
      "last_chat_message",
      %{"message" => %{"_id" => "m4", "text" => "Ready when you are", "user" => host}},
      1_200
    )
    |> State.apply_event(
      "chat_typing",
      %{"whoseTyping" => %{"sporcle_id//hostPlayer" => "Host"}},
      1_300
    )
  end

  # A honk from the host a moment ago, and the reactions everybody has had.
  defp reveal_reactions_player do
    s = Replay.first(&(&1.phase == :reveal and &1.judged), :join)

    s
    |> State.apply_event(
      "list_u2u",
      %{
        "u2u" => %{
          "sporcle_id//joinPlayer" => %{
            "total" => 3,
            "stream" => ["goose-1", "clap-2", "goose-3"],
            "byType" => %{}
          },
          "sporcle_id//hostPlayer" => %{"total" => 1, "stream" => ["trombone-4"]}
        },
        "u2uPerf" => %{"animate" => true, "disable" => false}
      },
      0
    )
    |> State.apply_event("honk", %{"peerId" => 1, "honk_type" => "goose"}, @now - 1_000)
  end

  # A game with pictures: the Popper this player paid to join it is spent as play starts.
  defp question_popper_notice_player do
    s = %{Replay.fresh(:question, :join) | poppers: 3}
    State.apply_event(s, "popper_spent", nil, 0)
  end

  # Two packs voted for, one of them by this player.
  defp lobby_player_votes do
    s = Replay.first(&(&1.phase == :lobby and map_size(&1.players) == 2), :join)
    pack = &%{"id" => &1, "name" => &2, "img_src" => "", "num_questions" => 50}

    State.apply_event(
      s,
      "pack_votes",
      %{
        "packVotes" => %{
          "268682" => %{
            "gamePack" => pack.(268_682, "World Capitals"),
            "voters" => ["sporcle_id//hostPlayer", "sporcle_id//joinPlayer"]
          },
          "1001" => %{"gamePack" => pack.(1001, "Flags"), "voters" => ["sporcle_id//hostPlayer"]}
        }
      },
      0
    )
  end

  # A host who hosts as a spectator: the joiner has answered, and the host sees only that.
  defp question_spectator_host do
    s = Replay.fresh(:question)
    s = put_in(s.players[1].spectate, true)

    State.apply_event(
      s,
      "list_answers",
      %{
        "questionIndex" => 0,
        "answer" => "الهند",
        "allPlayerAnswers" => [%{"peerId" => 2, "guessText" => "germany", "wagerAmount" => 1}]
      },
      0
    )
  end

  # Back in a question already answered, as Sporcle's game_connect puts a rejoin.
  defp question_rejoined_player do
    s = Replay.first(&(&1.phase == :question and &1.question.index == 1), :join)

    State.apply_event(
      %{s | sent: %{}, answers: %{}},
      "game_connect",
      %{
        "inLobby" => false,
        "currentView" => "GameAnswerWait",
        "questionIndex" => 1,
        "questionText" => s.question.text,
        "timeElapsed" => 4,
        "usedWagers" => %{"1" => false, "2" => nil},
        "questions" => [
          %{"questionIndex" => 0, "guessText" => "germany", "wagerAmount" => 1},
          %{"questionIndex" => 1, "guessText" => "france", "wagerAmount" => 2}
        ]
      },
      0
    )
  end

  defp reveal_rated_player do
    s = Replay.first(&(&1.phase == :reveal and &1.judged), :join)
    s |> State.rated(State.index(s), 1) |> State.reported(State.index(s), "typo")
  end

  defp lobby_notice_player do
    s = Replay.first(&(&1.phase == :lobby and map_size(&1.players) == 2), :join)

    State.apply_event(
      s,
      "server_message",
      %{
        "type" => "warn",
        "title" => "Scheduled maintenance",
        "message" => "Games will pause for a few minutes at 3:00 UTC.",
        "interval" => 8000
      },
      0
    )
  end

  defp final_scores_left_behind_player do
    s = Replay.fresh(:final_scores, :join)
    State.apply_event(%{s | played_again: false}, "leave_behind", %{"gameCode" => "771204"}, 0)
  end

  for name <- ~w(lobby_host question_player question_host_answered reveal_host
                 reveal_judged_player final_vote_player final_wager_host final_wager_player
                 final_question_player final_scores_host lobby_player_votes
                 question_countdown_player question_spectator_host question_rejoined_player
                 reveal_rated_player lobby_notice_player final_scores_left_behind_player
                 lobby_chat_player reveal_reactions_player question_popper_notice_player) do
    test "#{name} is what the relay sends" do
      name = unquote(name)
      state = Map.fetch!(snapshots(), name)
      # Times are relative to the recording; a fixture fixes them to @now. A countdown or a
      # notice is kept only where the fixture is about it.
      state = if state.deadline, do: %{state | deadline: @now + 15_000}, else: state

      state =
        if state.countdown && name =~ "countdown",
          do: %{
            state
            | countdown: %{state.countdown | until: @now + 3_000},
              deadline: @now + 3_000 + 15_000
          },
          else: %{state | countdown: nil}

      state =
        if state.notice && name =~ "notice",
          do: %{state | notice: %{state.notice | until: @now + 8_000}},
          else: %{state | notice: nil}

      json =
        state
        |> View.snapshot("624949", @now)
        |> Jason.encode!(pretty: true)

      path = Fixtures.path("snapshots/#{name}.json")

      if System.get_env("UPDATE_FIXTURES") do
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, json <> "\n")
      end

      assert Jason.decode!(json) == Jason.decode!(File.read!(path))
    end
  end
end
