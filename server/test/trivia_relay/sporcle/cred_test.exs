defmodule TriviaRelay.Sporcle.CredTest do
  use ExUnit.Case, async: true

  alias TriviaRelay.Sporcle.Cred

  @player %{
    "player_id" => "xAc71a08as",
    "token" => String.duplicate("a1", 32),
    "device_id" => "956aa24a2296d663",
    "handle" => "Anis"
  }

  test "takes the credentials the app sends" do
    assert {:ok, %Cred{player_id: "xAc71a08as", device_id: "956aa24a2296d663", handle: "Anis"}} =
             Cred.new(@player)
  end

  test "a name the player chose is cleaned like a handle, and shown in its place" do
    assert {:ok, %Cred{name: "Quiz Wiz", handle: "Anis"} = cred} =
             Cred.new(Map.put(@player, "name", " Quiz\u200B Wiz "))

    assert Cred.display_name(cred) == "Quiz Wiz"

    for nothing <- [nil, "", " \u202E ", 12] do
      assert {:ok, %Cred{name: nil} = cred} = Cred.new(Map.put(@player, "name", nothing))
      assert Cred.display_name(cred) == "Anis"
    end
  end

  test "refuses a device id the app wouldn't make, and ids of any other shape" do
    for {field, value} <- [
          {"device_id", "d3v"},
          {"device_id", "956AA24A2296D663"},
          {"device_id", "956aa24a2296d663\n"},
          {"player_id", "a b"},
          {"player_id", String.duplicate("a", 65)},
          {"token", "t\r\nx-evil: 1"},
          {"token", ""}
        ] do
      assert Cred.new(Map.put(@player, field, value)) == {:error, :invalid_player},
             "#{field} #{inspect(value)}"
    end
  end

  test "a handle keeps any script, and loses what only moves or hides text" do
    assert Cred.handle("أنيس عبد اللطيف") == "أنيس عبد اللطيف"
    assert Cred.handle("José 🎉 O'Neil-Smith") == "José 🎉 O'Neil-Smith"
    # A right-to-left override, zero-width and control characters.
    assert Cred.handle("ev\u202Eil\u200B\u0007 one") == "evil one"
    assert Cred.handle("  lots    of\tspace  ") == "lots of space"
    assert Cred.handle("\u2066\u2069") == "Player"
    assert Cred.handle(nil) == "Player"
    assert Cred.handle(<<0xFF>>) == "Player"
  end

  test "a handle is at most 40 characters, and marks don't stack without end" do
    assert String.length(Cred.handle(String.duplicate("م", 60))) == 40
    zalgo = "a" <> String.duplicate("\u0301", 50)
    assert Cred.handle(zalgo) == "a" <> String.duplicate("\u0301", 3)
  end

  test "the same credentials make the same key, and different ones don't" do
    {:ok, a} = Cred.new(@player)
    {:ok, b} = Cred.new(Map.put(@player, "token", "other"))
    assert Cred.key(a) == Cred.key(a)
    refute Cred.key(a) == Cred.key(b)
  end
end
