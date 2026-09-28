defmodule TriviaRelay.Replay do
  @moduledoc "Seat states taken from the recorded game (`protocol/fixtures/sporcle/hosted_game.json`)."

  alias TriviaRelay.Fixtures
  alias TriviaRelay.Seats.State

  @doc "Every state the host's seat went through, with the event that produced it."
  def states(as \\ :host) do
    %{"me" => me, "events" => events} = Fixtures.read!("sporcle/hosted_game.json")
    me = if as == :host, do: me, else: "sporcle_id//joinPlayer"

    Enum.scan(events, {State.new(me), nil}, fn e, {s, _} ->
      {State.apply_event(s, e["event"], e["payload"], e["t_ms"]), e}
    end)
  end

  @doc "The first state matching `fun`."
  def first(fun, as \\ :host) do
    {s, _} = Enum.find(states(as), fn {s, _} -> fun.(s) end)
    s
  end

  @doc "The first state in `phase`; for an open question, before anybody answered it."
  def fresh(phase, as \\ :host)

  def fresh(phase, as) when phase in [:question, :final_question] do
    first(&(&1.phase == phase and not Map.has_key?(&1.answers, &1.question.index)), as)
  end

  def fresh(phase, as), do: first(&(&1.phase == phase), as)
end
