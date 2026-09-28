defmodule TriviaRelay.ProtocolConstantsTest do
  use ExUnit.Case, async: true

  test "the relay's constants are the contract's (protocol/fixtures/constants.json)" do
    contract =
      TriviaRelay.Fixtures.read!("constants.json")
      |> Map.reject(fn {key, _} -> String.starts_with?(key, "_") end)

    assert TriviaRelay.Protocol.constants() == contract
  end
end
