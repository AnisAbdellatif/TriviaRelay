defmodule TriviaRelay.Protocol do
  @moduledoc """
  The phone ↔ relay contract's version and shared numbers (`protocol/PROTOCOL.md`).

  The version is `major.minor`, and only the major is on the wire: a relay refuses a
  phone whose major differs, and accepts any minor. Every fixed number both sides share
  is in `protocol/fixtures/constants.json`; `constants/0` gathers the relay's, and a test
  requires the two to be equal.
  """

  alias TriviaRelay.Seats.{Intents, Seat, State}
  alias TriviaRelay.Sporcle.Api

  @major 1
  @minor 1

  def major, do: @major
  def minor, do: @minor

  def constants do
    %{"protocol_version" => "#{@major}.#{@minor}"}
    |> Map.merge(State.constants())
    |> Map.merge(Intents.constants())
    |> Map.merge(Seat.constants())
    |> Map.merge(Api.constants())
  end
end
