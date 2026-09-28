defmodule TriviaRelayWeb.SeatControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  alias TriviaRelay.Seats

  @player %{
    "player_id" => "joinPlayer",
    "token" => "t0k3n",
    "device_id" => "d3v",
    "handle" => "Joiner"
  }

  defp session do
    %{
      "DnsName" => "x.amazongamelift.com",
      "Port" => 1914,
      "PlayerSessionId" => "psess-1",
      "test_pid" => self() |> :erlang.pid_to_list() |> to_string()
    }
  end

  defp stub(fun), do: Req.Test.stub(TriviaRelay.Sporcle, fun)

  test "joins a game by code and returns a seat to connect to", %{conn: conn} do
    session = session()

    stub(fn conn ->
      assert conn.request_path == "/api/party/joinGame"
      assert Plug.Conn.get_req_header(conn, "x-sporcle-token") == ["t0k3n"]
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert Jason.decode!(body) == %{"gameCode" => "624949"}
      Req.Test.json(conn, %{"playerSession" => session})
    end)

    conn = post(conn, ~p"/api/seats", %{"code" => "624949", "player" => @player})

    assert %{"seat_id" => id, "seat_token" => token, "game_code" => "624949"} =
             json_response(conn, 201)

    assert {:ok, ^id} = Seats.verify(token)
    assert Seats.whereis(id)

    # The player's login, without game options: only a host sends those.
    assert_receive {:fake_upstream, _, _, player}
    assert player["playerId"] == "sporcle_id//joinPlayer"
    refute Map.has_key?(player, "gameOptions")
  end

  test "hosts a game, sending the options with createGame and again in the login", %{conn: conn} do
    session = session()

    stub(fn conn ->
      case conn.request_path do
        "/api/party/getPack" ->
          Req.Test.json(conn, %{"pack" => %{"id" => 156_070, "name" => "Flags"}})

        "/api/party/createGame" ->
          {:ok, body, conn} = Plug.Conn.read_body(conn)

          assert %{"gameOptions" => %{"QUESTIONS_PER_GAME" => 5, "AUDIENCE_TYPE" => "private"}} =
                   Jason.decode!(body)

          Req.Test.json(conn, %{"gameCode" => "111222", "playerSession" => session})
      end
    end)

    options = %{"questions_per_game" => 5, "question_seconds" => 15, "audience" => "private"}

    conn =
      post(conn, ~p"/api/seats/host", %{
        "pack_id" => 156_070,
        "options" => options,
        "player" => @player
      })

    assert %{"game_code" => "111222"} = json_response(conn, 201)

    assert_receive {:fake_upstream, _, _, player}
    assert player["isHost"]
    assert %{"QUESTION_SECONDS" => 15, "AUDIENCE_TYPE" => "private"} = player["gameOptions"]
  end

  describe "changing the pack" do
    # A seat in a lobby, as the host or not.
    defp seated(conn, host?) do
      session = session()
      stub(&Req.Test.json(&1, %{"playerSession" => session}))
      conn = post(conn, ~p"/api/seats", %{"code" => "624949", "player" => @player})
      %{"seat_id" => id, "seat_token" => token} = json_response(conn, 201)

      send(
        Seats.whereis(id),
        {:upstream, "test",
         {:event, "game_info",
          %{
            "allPlayers" => [
              %{"peerId" => 1, "playerId" => "sporcle_id//joinPlayer", "isHost" => host?},
              %{"peerId" => 2, "playerId" => "sporcle_id//other", "isHost" => not host?}
            ]
          }}}
      )

      token
    end

    defp change(conn, token) do
      post(conn, ~p"/api/seats/pack", %{
        "seat_token" => token,
        "pack_id" => 268_682,
        "player" => @player
      })
    end

    test "the host's goes to Sporcle as the whole pack", %{conn: conn} do
      token = seated(conn, true)

      stub(fn conn ->
        assert conn.request_path == "/api/party/getPack"
        assert Plug.Conn.get_req_header(conn, "x-sporcle-token") == ["t0k3n"]
        Req.Test.json(conn, %{"pack" => %{"id" => 268_682, "name" => "Capitals"}})
      end)

      assert response(change(conn, token), 204)

      assert_receive {:sent, "change_pack", %{gamePack: %{"id" => 268_682, "name" => "Capitals"}}}
    end

    test "anybody else is refused", %{conn: conn} do
      token = seated(conn, false)
      stub(&Req.Test.json(&1, %{"pack" => %{"id" => 268_682}}))
      assert %{"code" => "not_host"} = json_response(change(conn, token), 409)
      refute_received {:sent, "change_pack", _}
    end

    test "a seat token that isn't genuine is refused before Sporcle", %{conn: conn} do
      stub(fn _ -> flunk("Sporcle was called") end)
      assert %{"code" => "invalid_token"} = json_response(change(conn, "forged"), 401)
    end
  end

  test "an expired Sporcle sign-in says so", %{conn: conn} do
    stub(&Plug.Conn.send_resp(&1, 401, "{}"))
    conn = post(conn, ~p"/api/seats", %{"code" => "624949", "player" => @player})
    assert %{"code" => "sporcle_auth"} = json_response(conn, 401)
  end

  test "a refusal passes on what Sporcle said", %{conn: conn} do
    stub(&Req.Test.json(&1, %{"error" => "Game not found"}))
    conn = post(conn, ~p"/api/seats", %{"code" => "624949", "player" => @player})
    assert %{"code" => "game_refused", "message" => "Game not found"} = json_response(conn, 409)
  end

  test "bad requests never reach Sporcle", %{conn: conn} do
    stub(fn _ -> flunk("Sporcle was called") end)

    assert %{"code" => "invalid_code"} =
             conn
             |> post(~p"/api/seats", %{"code" => "abc", "player" => @player})
             |> json_response(400)

    assert %{"code" => "invalid_player"} =
             conn |> post(~p"/api/seats", %{"code" => "624949"}) |> json_response(400)

    assert %{"code" => "invalid_options"} =
             conn
             |> post(~p"/api/seats/host", %{
               "pack_id" => 1,
               "options" => %{"question_seconds" => 20},
               "player" => @player
             })
             |> json_response(400)
  end
end
