defmodule TriviaRelay.Fixtures do
  @moduledoc "The shared fixtures in `protocol/fixtures/` (the contract both sides test against)."

  @root Path.expand("../../../protocol/fixtures", __DIR__)

  def path(name), do: Path.join(@root, name)
  def read!(name), do: name |> path() |> File.read!() |> Jason.decode!()
end
