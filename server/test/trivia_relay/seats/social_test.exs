defmodule TriviaRelay.Seats.SocialTest do
  @moduledoc "The chat, reactions and Party Poppers: folding Sporcle's events, and the intents."

  use ExUnit.Case, async: true

  alias TriviaRelay.Replay
  alias TriviaRelay.Seats.{Intents, State, View}

  @host %{"_id" => "sporcle_id//hostPlayer", "peerId" => 1, "name" => "Hosta"}

  # The joiner in the recorded game's lobby: the host is peer 1, this seat peer 2.
  defp lobby, do: Replay.first(&(&1.phase == :lobby and map_size(&1.players) == 2), :join)

  defp message(id, text, user \\ @host), do: %{"_id" => id, "text" => text, "user" => user}

  defp chat(s, now \\ 0), do: View.snapshot(s, "624949", now).chat

  describe "the chat, as Sporcle sends it" do
    test "a message while the chat is closed counts as unread, once" do
      s = lobby()
      s = State.apply_event(s, "last_chat_message", %{"message" => message("a", "hi")}, 10)
      s = State.apply_event(s, "chat_message", %{"message" => message("a", "hi")}, 11)

      assert %{unread: 1, messages: [%{id: "a", text: "hi", name: "Hosta", peer_id: 1}]} =
               chat(s)
    end

    test "while the chat is open nothing is unread, and opening reads what was" do
      s = State.apply_event(lobby(), "chat_has_message", %{}, 0)
      assert chat(s).unread == 1

      s = State.chat_opened(s)
      s = State.apply_event(s, "chat_message", %{"message" => message("b", "yo")}, 5)
      assert %{unread: 0, open: true, messages: [%{id: "b"}]} = chat(s)
    end

    test "the history on opening is newest first, and kept in time order with what came before" do
      s = State.apply_event(lobby(), "last_chat_message", %{"message" => message("c", "3")}, 300)

      s =
        State.apply_event(
          State.chat_opened(s),
          "chat_load",
          %{
            "messages" => [
              Map.put(message("c", "3"), "createdAt", 300),
              Map.put(message("b", "2"), "createdAt", "1970-01-01T00:00:00.200Z"),
              Map.put(message("a", "1"), "createdAt", 100)
            ],
            "hasMore" => true
          },
          400
        )

      assert %{messages: messages, has_more: true, unread: 0} = chat(s)
      assert Enum.map(messages, & &1.id) == ~w(a b c)
      assert Enum.map(messages, & &1.at) == [100, 200, 300]
    end

    test "a message says it was written no later than it arrived" do
      s =
        State.apply_event(
          lobby(),
          "chat_load",
          %{"messages" => [Map.put(message("a", "x"), "createdAt", 9_999_999_999_999)]},
          500
        )

      assert [%{at: 500}] = chat(s).messages
    end

    test "names and words are cleaned and bounded; a message with neither words nor picture is dropped" do
      long = String.duplicate("é", 600)
      user = %{"_id" => "sporcle_id//x", "name" => "Eve\u202E"}

      s =
        lobby()
        |> State.apply_event(
          "chat_message",
          %{"message" => message("a", "\u200Bhi\u202E", user)},
          1
        )
        |> State.apply_event("chat_message", %{"message" => message("b", long, user)}, 2)
        |> State.apply_event("chat_message", %{"message" => message("c", "  ", user)}, 3)
        |> State.apply_event("chat_message", %{"message" => "nope"}, 4)
        |> State.apply_event(
          "chat_message",
          %{"message" => %{"_id" => "d", "image" => "https://x.test/a.gif", "user" => user}},
          5
        )
        |> State.apply_event(
          "chat_message",
          %{"message" => %{"_id" => "e", "image" => "http://x.test/a.gif", "user" => user}},
          6
        )

      assert [a, b, d] = chat(s).messages
      assert %{text: "hi", name: "Eve", peer_id: nil} = a
      assert String.length(b.text) == 512
      assert %{text: "", image_url: "https://x.test/a.gif"} = d
    end

    test "keeps the last 50, and a snapshot carries the last 20 until the phone asks for more" do
      s =
        Enum.reduce(1..60, State.chat_opened(lobby()), fn i, s ->
          State.apply_event(s, "chat_message", %{"message" => message("m#{i}", "#{i}")}, i)
        end)

      assert length(s.chat.messages) == State.chat_history()
      assert %{messages: shown, has_more: true} = chat(s)
      assert length(shown) == 20 and List.last(shown).id == "m60"

      assert {:ok, [], s} = Intents.handle(s, "chat_more", %{})
      assert length(chat(s).messages) == 40
      assert {:ok, [], s} = Intents.handle(s, "chat_more", %{})
      assert %{messages: shown, has_more: false} = chat(s)
      assert length(shown) == 50
      assert {:ok, [], ^s} = Intents.handle(s, "chat_more", %{})

      # Closing goes back to the latest.
      assert length(chat(State.chat_closed(s)).messages) == 20
    end

    test "asks Sporcle for earlier pages while it has more, one at a time" do
      s =
        State.apply_event(
          State.chat_opened(lobby()),
          "chat_load",
          %{"messages" => [Map.put(message("a", "1"), "createdAt", 10)], "hasMore" => true},
          20
        )

      assert {:ok, [{"chat_load_more", %{page: 1}}], s} = Intents.handle(s, "chat_more", %{})
      assert chat(s).loading
      assert {:ok, [], ^s} = Intents.handle(s, "chat_more", %{})

      s =
        State.apply_event(
          s,
          "chat_load_more",
          %{"messages" => [Map.put(message("z", "0"), "createdAt", 5)], "hasMore" => false},
          30
        )

      assert %{loading: false, has_more: false, messages: [%{id: "z"}, %{id: "a"}]} = chat(s)
    end

    test "says who else is typing, and a message ends it" do
      me = lobby().me

      s =
        State.apply_event(
          lobby(),
          "chat_typing",
          %{"whoseTyping" => %{"sporcle_id//hostPlayer" => "Hosta", me => "Joiner", 7 => "x"}},
          0
        )

      assert chat(s).typing == ["Hosta"]
      s = State.apply_event(s, "chat_message", %{"message" => message("a", "done")}, 1)
      assert chat(s).typing == []
    end
  end

  describe "chatting" do
    test "a message goes to everyone as the official app's, and shows as this player's" do
      s = State.chat_opened(lobby())

      assert {:ok, [{"chat_message", %{message: sent}}], s} =
               Intents.handle(s, "chat_send", %{"text" => "  hello \u202Ethere "}, %{
                 now: 1_790_000_000_000,
                 id: "uuid-1"
               })

      assert %{
               "_id" => "uuid-1",
               "text" => "hello there",
               "createdAt" => "2026-09-21T14:13:20.000Z",
               "user" => %{"_id" => "sporcle_id//joinPlayer", "peerId" => 2, "name" => "Joiner"}
             } = sent

      assert [%{id: "uuid-1", own: true, name: "Joiner", peer_id: 2, text: "hello there"}] =
               chat(s, 1_790_000_000_000).messages

      # Sporcle echoing it wouldn't show it twice.
      s = State.apply_event(s, "chat_message", %{"message" => sent}, 5)
      assert length(chat(s).messages) == 1
    end

    test "is cut to the official field's 256 characters; an empty one is refused" do
      s = lobby()
      text = String.duplicate("a", 300)

      assert {:ok, [{"chat_message", %{message: %{"text" => sent}}}], _} =
               Intents.handle(s, "chat_send", %{"text" => text}, %{now: 0, id: "x"})

      assert String.length(sent) == 256
      assert {:error, "invalid_intent"} = Intents.handle(s, "chat_send", %{"text" => " \n "})
      assert {:error, "invalid_intent"} = Intents.handle(s, "chat_send", %{"text" => 5})
    end

    test "typing is said as it starts and stops, while the chat is open, and sending stops it" do
      s = lobby()
      assert {:ok, [], ^s} = Intents.handle(s, "chat_typing", %{"typing" => true})

      s = State.chat_opened(s)

      assert {:ok, [{"chat_start_typing", :none}], s} =
               Intents.handle(s, "chat_typing", %{"typing" => true})

      assert {:ok, [], ^s} = Intents.handle(s, "chat_typing", %{"typing" => true})

      assert {:ok, [{"chat_message", _}, {"chat_stop_typing", :none}], s} =
               Intents.handle(s, "chat_send", %{"text" => "x"}, %{now: 0, id: "a"})

      assert {:ok, [], _} = Intents.handle(s, "chat_typing", %{"typing" => false})
    end

    test "the chat opens and closes with the phones, never before the seat is in the game" do
      s = lobby()
      assert {[{"chat_open", :none}], s} = Intents.chat_view(s, true)
      assert {[], ^s} = Intents.chat_view(s, true)

      {_, s} =
        Intents.handle(s, "chat_typing", %{"typing" => true})
        |> then(fn {:ok, m, s} -> {m, s} end)

      assert {[{"chat_stop_typing", :none}, {"chat_close", :none}], s} =
               Intents.chat_view(s, false)

      assert {[], _} = Intents.chat_view(s, false)

      assert {[], _} = Intents.chat_view(State.new("sporcle_id//me"), true)
    end
  end

  describe "reactions" do
    test "a honk goes to that player alone, then to the game to be counted" do
      s = lobby()

      assert {:ok,
              [
                {:to, 1, "honk", %{peerId: 2, honk_type: "goose"}},
                {"send_u2u", %{playerId: "sporcle_id//hostPlayer", peerId: 1, type: "goose"}}
              ], s} = Intents.handle(s, "honk", %{"peer_id" => 1}, %{now: 10_000})

      assert {:error, "rate_limited"} =
               Intents.handle(s, "honk", %{"peer_id" => 1}, %{now: 11_999})

      assert {:ok, _, _} = Intents.handle(s, "honk", %{"peer_id" => 1}, %{now: 12_000})
    end

    test "only the free sounds, only to another player who is there" do
      s = lobby()

      assert {:ok, [{:to, 1, "honk", %{honk_type: "goose"}}, _], _} =
               Intents.handle(s, "react", %{"peer_id" => 1, "type" => "goose"}, %{now: 0})

      assert {:error, "invalid_intent"} =
               Intents.handle(s, "react", %{"peer_id" => 1, "type" => "trombone"}, %{now: 0})

      assert {:error, "invalid_intent"} = Intents.handle(s, "honk", %{"peer_id" => 2}, %{now: 0})
      assert {:error, "invalid_intent"} = Intents.handle(s, "honk", %{"peer_id" => 9}, %{now: 0})

      assert {:error, "invalid_intent"} =
               Intents.handle(s, "honk", %{"peer_id" => "1"}, %{now: 0})

      away = put_in(s.players[1].connected, false)

      assert {:error, "invalid_intent"} =
               Intents.handle(away, "honk", %{"peer_id" => 1}, %{now: 0})
    end

    test "one received shows for a few seconds, from whoever sent it" do
      s = State.apply_event(lobby(), "honk", %{"peerId" => 1, "honk_type" => "trombone"}, 1_000)

      assert [%{id: 1, peer_id: 1, type: "trombone", until: 5_000}] =
               View.snapshot(s, "624949", 4_999).reactions

      assert [] = View.snapshot(s, "624949", 5_000).reactions
    end

    test "not this player's own, not a burst faster than the official app plays, not junk" do
      s =
        lobby()
        |> State.apply_event("honk", %{"peerId" => 2, "honk_type" => "goose"}, 0)
        |> State.apply_event("honk", %{"peerId" => 1, "honk_type" => "goose"}, 1_000)
        |> State.apply_event("honk", %{"peerId" => 1, "honk_type" => "goose"}, 1_100)
        |> State.apply_event("honk", %{"peerId" => 1, "honk_type" => "<script>"}, 1_500)
        |> State.apply_event("honk", %{"peerId" => "1", "honk_type" => "goose"}, 1_600)
        |> State.apply_event("honk", %{"peerId" => 1, "honk_type" => "clap"}, 1_700)

      assert [%{at: 1_000}, %{at: 1_700, type: "clap"}] = s.reactions.received

      s =
        Enum.reduce(1..30, s, fn i, s ->
          State.apply_event(s, "honk", %{"peerId" => 1, "honk_type" => "goose"}, 2_000 + i * 300)
        end)

      assert length(s.reactions.received) == 10
    end

    test "everybody's counts, from the list, with the latest few sounds" do
      s =
        State.apply_event(
          lobby(),
          "list_u2u",
          %{
            "u2u" => %{
              "sporcle_id//hostPlayer" => %{
                "total" => 9,
                "stream" => ~w(goose-1 clap-2 bogus-3 laugh-4 aww-5 ooh-6 tuba-7)
              },
              "sporcle_id//joinPlayer" => %{"total" => -4, "stream" => "x"}
            }
          },
          0
        )

      assert [host, me] = View.snapshot(s, "624949", 0).players
      assert host.reactions == %{total: 9, recent: ~w(clap laugh aww ooh tuba)}
      assert me.reactions == %{total: 0, recent: []}
    end
  end

  describe "Party Poppers" do
    test "one spent comes off the count, and the player is told" do
      s = State.new("sporcle_id//me", 2)
      s = State.apply_event(s, "popper_spent", nil, 100)
      assert %{you: %{poppers: 1}, notice: %{kind: "popper_spent"}} = View.snapshot(s, "1", 100)

      s =
        State.apply_event(State.apply_event(s, "popper_spent", %{}, 200), "popper_spent", 1, 300)

      assert s.poppers == 0
    end

    test "unknown stays unknown" do
      s = State.apply_event(State.new("sporcle_id//me"), "popper_spent", nil, 0)
      assert %{you: %{poppers: nil}, notice: %{kind: "popper_spent"}} = View.snapshot(s, "1", 0)
    end
  end

  test "a seat taking over another's in the same game keeps its chat" do
    old = State.apply_event(lobby(), "chat_message", %{"message" => message("a", "hi")}, 1)
    s = State.carry_over(lobby(), old)
    assert [%{id: "a"}] = s.chat.messages
  end
end
