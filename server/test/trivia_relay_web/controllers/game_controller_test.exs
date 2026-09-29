defmodule TriviaRelayWeb.GameControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  alias TriviaRelayWeb.GameController

  defp list(conn) do
    conn
    |> put_req_header("x-player-id", "p1")
    |> put_req_header("x-player-token", "t")
    |> put_req_header("x-device-id", "0123456789abcdef")
    |> get(~p"/api/games")
  end

  # A joinable game as Sporcle lists it (confirmed live).
  defp sporcle_game(code, screen, extra \\ %{}) do
    Map.merge(
      %{
        "creationTime" => "2026-09-28T06:14:24+00:00",
        "currentHost" => "sporcle_id//h1",
        "distance" => 4362.03,
        "gameCode" => code,
        "gamePack" => %{
          "description" => "🌴",
          "id" => "593045",
          "img_src" => "https://static.sporcle.com/pack_images/593045",
          "name" => "Flags"
        },
        "gameScreen" => screen,
        "hasImages" => false,
        "host" => %{"playerId" => "sporcle_id//h1", "sporcleHandle" => "Hosty"},
        "location" => ["24.68690", "46.72240"],
        "playerCount" => 4
      },
      extra
    )
  end

  test "lists Sporcle's joinable games with the caller's credentials", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      assert conn.request_path == "/api/party/getJoinableGames"
      assert Plug.Conn.get_req_header(conn, "x-sporcle-player") == ["p1"]
      assert Plug.Conn.get_req_header(conn, "x-sporcle-token") == ["t"]

      Req.Test.json(conn, %{
        "friendGames" => [],
        "invitedGames" => [],
        "publicGames" => [sporcle_game("787720", "Lobby")]
      })
    end)

    assert %{
             "games" => [
               %{
                 "code" => "787720",
                 "list" => "public",
                 "pack" => %{
                   "id" => 593_045,
                   "name" => "Flags",
                   "description" => "🌴",
                   "image_url" => "https://static.sporcle.com/pack_images/593045"
                 },
                 "host" => "Hosty",
                 "player_count" => 4,
                 "stage" => "lobby",
                 "question_number" => nil,
                 "has_images" => false
               } = game
             ]
           } = conn |> list() |> json_response(200)

    refute Map.has_key?(game, "location"), "nothing of where anybody is"
  end

  test "invited, then friends, then public, lobbies first; each game once", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      Req.Test.json(conn, %{
        "publicGames" => [
          sporcle_game("100", "Question 3"),
          sporcle_game("200", "Lobby"),
          sporcle_game("300", "Lobby")
        ],
        "friendGames" => [sporcle_game("400", "Final Question"), sporcle_game("300", "Lobby")],
        "invitedGames" => [sporcle_game("500", "Question 1")]
      })
    end)

    games = conn |> list() |> json_response(200) |> Map.fetch!("games")

    assert Enum.map(games, &{&1["code"], &1["list"]}) == [
             {"500", "invited"},
             {"300", "friends"},
             {"400", "friends"},
             {"200", "public"},
             {"100", "public"}
           ]
  end

  test "the fullest games first, lobbies before games under way", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      Req.Test.json(conn, %{
        "publicGames" => [
          sporcle_game("1", "Lobby", %{"playerCount" => 1}),
          sporcle_game("2", "Question 2", %{"playerCount" => 9}),
          sporcle_game("3", "Lobby", %{"playerCount" => 6}),
          sporcle_game("4", "Lobby", %{"playerCount" => nil}),
          sporcle_game("5", "Question 5", %{"playerCount" => 12})
        ]
      })
    end)

    games = conn |> list() |> json_response(200) |> Map.fetch!("games")
    assert Enum.map(games, & &1["code"]) == ["3", "1", "4", "5", "2"]
  end

  test "a game without a code, or a pack, doesn't break the list", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      Req.Test.json(conn, %{
        "publicGames" => [
          Map.delete(sporcle_game("1", "Lobby"), "gameCode"),
          sporcle_game("2", "Lobby", %{"gamePack" => nil})
        ]
      })
    end)

    assert %{"games" => [%{"code" => "2", "pack" => nil}]} = conn |> list() |> json_response(200)
  end

  test "reads where a game is from Sporcle's screen name" do
    assert GameController.stage("Lobby") == {"lobby", nil}
    assert GameController.stage("Question 8") == {"question", 8}
    assert GameController.stage("Final Question") == {"final", nil}
    assert GameController.stage("Scores") == {"playing", nil}
    assert GameController.stage(nil) == {"playing", nil}
  end

  test "an expired Sporcle sign-in says so", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, &Plug.Conn.send_resp(&1, 401, ""))

    assert %{"code" => "sporcle_auth"} = conn |> list() |> json_response(401)
  end

  test "needs credentials", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
    assert %{"code" => "invalid_player"} = conn |> get(~p"/api/games") |> json_response(400)
  end
end
