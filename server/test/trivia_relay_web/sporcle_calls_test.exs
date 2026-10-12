defmodule TriviaRelayWeb.SporcleCallsTest do
  # Caching and the in-flight ceiling are global switches, so these run on their own.
  use TriviaRelayWeb.ConnCase, async: false

  alias TriviaRelay.Cache
  alias TriviaRelayWeb.SporcleErrors

  setup do
    Application.put_env(:trivia_relay, :cache_enabled, true)
    Cache.clear()

    on_exit(fn ->
      Application.put_env(:trivia_relay, :cache_enabled, false)
      Application.delete_env(:trivia_relay, :sporcle_max_in_flight)
      Application.delete_env(:trivia_relay, :sporcle_timeout_ms)
      Cache.clear()
    end)
  end

  defp as(conn, id, token) do
    conn
    |> put_req_header("x-player-id", id)
    |> put_req_header("x-player-token", token)
    |> put_req_header("x-device-id", "0123456789abcdef")
  end

  defp counting(response) do
    counter = :counters.new(1, [])

    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      :counters.add(counter, 1, 1)
      Req.Test.json(conn, response)
    end)

    fn -> :counters.get(counter, 1) end
  end

  describe "the games list" do
    @games %{"publicGames" => [%{"gameCode" => "787720", "gameScreen" => "Lobby"}]}

    test "is kept a few seconds for the same credentials", %{conn: conn} do
      calls = counting(@games)

      for _ <- 1..3 do
        assert %{"games" => [%{"code" => "787720"}]} =
                 conn |> as("p1", "t") |> get(~p"/api/games") |> json_response(200)
      end

      assert calls.() == 1
    end

    test "is never another player's, nor the same player's with another token", %{conn: conn} do
      calls = counting(@games)

      conn |> as("p1", "t") |> get(~p"/api/games") |> json_response(200)
      conn |> as("p2", "t") |> get(~p"/api/games") |> json_response(200)
      conn |> as("p1", "guessed") |> get(~p"/api/games") |> json_response(200)

      assert calls.() == 3
    end

    test "keeps no failure", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Plug.Conn.send_resp(&1, 500, "{}"))
      assert json_response(conn |> as("p1", "t") |> get(~p"/api/games"), 502)

      calls = counting(@games)
      assert json_response(conn |> as("p1", "t") |> get(~p"/api/games"), 200)
      assert calls.() == 1
    end
  end

  describe "pack lists" do
    @packs %{"data" => %{"packs" => [%{"id" => 1, "name" => "A"}]}}

    test "the lists everybody sees are kept a minute, for everybody", %{conn: conn} do
      calls = counting(@packs)

      for id <- ["p1", "p2"] do
        assert %{"packs" => [%{"id" => 1}]} =
                 conn
                 |> as(id, "t")
                 |> get(~p"/api/packs?list=popular&page=0")
                 |> json_response(200)
      end

      assert calls.() == 1
    end

    test "a player's own lists, and searches, are asked every time", %{conn: conn} do
      calls = counting(@packs)

      for path <- [
            ~p"/api/packs?list=bookmarked",
            ~p"/api/packs?list=bookmarked",
            ~p"/api/packs?list=popular&q=flags",
            ~p"/api/packs?list=popular&q=flags",
            ~p"/api/packs?q=flags"
          ] do
        assert json_response(conn |> as("p1", "t") |> get(path), 200)
      end

      assert calls.() == 5
    end

    test "a kept list says nothing of the player it was asked for", %{conn: conn} do
      counting(%{"data" => %{"packs" => [%{"id" => 1, "bookmarked" => true}]}})

      for id <- ["p1", "p2"] do
        assert %{"packs" => [%{"id" => 1, "bookmarked" => nil, "subscribed" => nil}]} =
                 conn
                 |> as(id, "t")
                 |> get(~p"/api/packs?list=popular")
                 |> json_response(200)
      end

      # A player's own list, never kept, says it.
      assert %{"packs" => [%{"bookmarked" => true}]} =
               conn
               |> as("p1", "t")
               |> get(~p"/api/packs?list=bookmarked")
               |> json_response(200)
    end

    test "a pack and a random one are asked every time", %{conn: conn} do
      calls = counting(%{"pack" => %{"id" => 9, "name" => "Nine", "bookmarked" => true}})

      for path <- [~p"/api/packs/9", ~p"/api/packs/9", ~p"/api/packs/random"] do
        assert %{"pack" => %{"id" => 9, "bookmarked" => true}} =
                 conn |> as("p1", "t") |> get(path) |> json_response(200)
      end

      assert calls.() == 3
    end
  end

  describe "friends" do
    @friends %{"friends" => %{"f1" => %{"sporcleHandle" => "ana"}}}

    test "are kept a few seconds for the same credentials, never anybody else's", %{conn: conn} do
      calls = counting(@friends)

      for _ <- 1..2, id <- ["p1", "p2"] do
        assert %{"friends" => [%{"id" => "f1"}]} =
                 conn |> as(id, "t") |> get(~p"/api/friends") |> json_response(200)
      end

      assert calls.() == 2
    end
  end

  describe "calls to Sporcle" do
    test "past the ceiling in flight, fail at once without reaching it", %{conn: conn} do
      Application.put_env(:trivia_relay, :sporcle_max_in_flight, 0)
      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)

      conn = conn |> as("p1", "t") |> get(~p"/api/packs?q=x")
      assert %{"code" => "relay_busy"} = json_response(conn, 503)
      assert get_resp_header(conn, "retry-after") == ["5"]
    end

    test "are abandoned once they take too long", %{conn: conn} do
      Application.put_env(:trivia_relay, :sporcle_timeout_ms, 50)

      Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
        Process.sleep(500)
        Req.Test.json(conn, %{})
      end)

      conn = conn |> as("p1", "t") |> get(~p"/api/packs?q=x")
      assert %{"code" => "sporcle_unavailable"} = json_response(conn, 502)
    end

    test "each gives its place back when done", %{conn: conn} do
      Application.put_env(:trivia_relay, :sporcle_max_in_flight, 1)
      counting(@packs)

      for _ <- 1..3 do
        assert json_response(conn |> as("p1", "t") |> get(~p"/api/packs?q=x"), 200)
        wait_until(fn -> TriviaRelay.RateLimit.held(:sporcle_in_flight, "all") == 0 end)
      end
    end
  end

  test "a full relay refuses a seat before Sporcle is asked", %{conn: conn} do
    Application.put_env(:trivia_relay, :max_seats, 0)
    on_exit(fn -> Application.delete_env(:trivia_relay, :max_seats) end)
    Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)

    player = %{"player_id" => "p1", "token" => "t", "device_id" => "0123456789abcdef"}
    conn = post(conn, ~p"/api/seats", %{"code" => "624949", "player" => player})
    assert %{"code" => "seats_full"} = json_response(conn, 503)
  end

  test "a full relay says so, whichever way the seats say it", %{conn: conn} do
    for reason <- [:seats_full, {:seat_failed, :max_children}, :relay_full] do
      conn = SporcleErrors.send(conn, {:error, reason})
      assert %{"code" => "seats_full"} = json_response(conn, 503), inspect(reason)
    end

    assert %{"code" => "sporcle_unavailable"} =
             conn |> SporcleErrors.send({:error, {:seat_failed, :boom}}) |> json_response(502)
  end

  defp wait_until(fun, tries \\ 50) do
    cond do
      fun.() -> :ok
      tries == 0 -> flunk("never happened")
      true -> Process.sleep(10) && wait_until(fun, tries - 1)
    end
  end
end
