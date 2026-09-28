defmodule TriviaRelay.SnapshotFixturesTest do
  @moduledoc """
  The snapshots in `protocol/fixtures/snapshots/` are what the relay sends a phone at
  moments of the recorded game, and the app's tests parse the same files: this is
  what holds the two sides to one `state` (PROTOCOL.md §5.1). Regenerate them after
  a deliberate change with `UPDATE_FIXTURES=1 mix test`.
  """

  use ExUnit.Case, async: true

  alias TriviaRelay.{Fixtures, Replay}
  alias TriviaRelay.Seats.View

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
      "final_question_player" => Replay.fresh(:final_question, :join),
      "final_scores_host" => Replay.fresh(:final_scores)
    }
  end

  for name <- ~w(lobby_host question_player question_host_answered reveal_host
                 reveal_judged_player final_vote_player final_wager_host
                 final_question_player final_scores_host) do
    test "#{name} is what the relay sends" do
      name = unquote(name)
      state = Map.fetch!(snapshots(), name)
      # Deadlines are relative to the recording; a fixture fixes them to @now.
      state = if state.deadline, do: %{state | deadline: @now + 15_000}, else: state

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
