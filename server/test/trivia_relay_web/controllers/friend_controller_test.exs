defmodule TriviaRelayWeb.FriendControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  alias TriviaRelay.Seats

  @player %{
    "player_id" => "hostPlayer",
    "token" => "t0k3n",
    "device_id" => "0123456789abcdef",
    "handle" => "Host"
  }

  defp as_player(conn, id \\ "hostPlayer") do
    conn
    |> put_req_header("x-player-id", id)
    |> put_req_header("x-player-token", "t0k3n")
    |> put_req_header("x-device-id", "0123456789abcdef")
  end

  defp stub(fun), do: Req.Test.stub(TriviaRelay.Sporcle, fun)

  describe "the friends list" do
    test "is the accepted friends, by the id an invitation takes, by name", %{conn: conn} do
      stub(fn conn ->
        assert conn.request_path == "/api/party/getFriends"
        assert Plug.Conn.fetch_query_params(conn).query_params == %{"page" => "0"}

        Req.Test.json(conn, %{
          "friends" => %{
            "xB2" => %{
              "sporcleHandle" => "zed",
              "teamName" => "Zed \u202Ethe Great",
              "friendStatus" => %{"is_friend" => true}
            },
            "xA1" => %{"sporcleHandle" => "ana", "friendStatus" => %{"is_friend" => true}},
            "xC3" => %{"sporcleHandle" => "asked", "friendStatus" => %{"sent" => true}},
            "bad id!" => %{"sporcleHandle" => "odd"}
          }
        })
      end)

      assert %{
               "friends" => [
                 %{"id" => "xA1", "name" => "ana", "handle" => "ana"},
                 %{"id" => "xB2", "name" => "Zed the Great", "handle" => "zed"}
               ],
               "next_page" => 1
             } = conn |> as_player() |> get(~p"/api/friends") |> json_response(200)
    end

    test "ends with an empty page", %{conn: conn} do
      stub(&Req.Test.json(&1, %{"friends" => []}))

      assert %{"friends" => [], "next_page" => nil} =
               conn |> as_player() |> get(~p"/api/friends?page=3") |> json_response(200)
    end
  end

  describe "invitations" do
    # A seat for the host, as POST /api/seats/host makes one; the rest of Sporcle
    # answers `sporcle`.
    defp seated(conn, sporcle) do
      session = %{
        "DnsName" => "x.amazongamelift.com",
        "Port" => 1914,
        "PlayerSessionId" => "psess-1",
        "test_pid" => self() |> :erlang.pid_to_list() |> to_string()
      }

      stub(fn conn ->
        case conn.request_path do
          "/api/party/joinGame" -> Req.Test.json(conn, %{"playerSession" => session})
          _ -> sporcle.(conn)
        end
      end)

      %{"seat_id" => id, "seat_token" => token} =
        conn
        |> post(~p"/api/seats", %{"code" => "624949", "player" => @player})
        |> json_response(201)

      # The seat claims its player as it starts.
      :sys.get_state(Seats.whereis(id))
      token
    end

    defp invite(conn, body), do: conn |> as_player() |> post(~p"/api/invites", body)

    test "invite one friend to the game, with the pack as Sporcle has it", %{conn: conn} do
      test = self()

      token =
        seated(conn, fn conn ->
          case conn.request_path do
            "/api/party/getPack" ->
              Req.Test.json(conn, %{
                "pack" => %{"id" => 7, "name" => "Flags", "img_src" => "https://x/7"}
              })

            "/api/party/inviteToGame" ->
              {:ok, body, conn} = Plug.Conn.read_body(conn)
              send(test, {:invited, Jason.decode!(body)})
              Req.Test.json(conn, %{})
          end
        end)

      conn =
        invite(conn, %{
          "seat_token" => token,
          "code" => "624949",
          "pack_id" => 7,
          "friend_id" => "xA1"
        })

      assert response(conn, 204)

      assert_received {:invited,
                       %{
                         "friend_uid" => "xA1",
                         "game" => %{
                           "gameCode" => "624949",
                           "gamePack" => %{
                             "id" => 7,
                             "name" => "Flags",
                             "img_src" => "https://x/7"
                           }
                         }
                       }}
    end

    test "invite every friend at once", %{conn: conn} do
      test = self()

      token =
        seated(conn, fn conn ->
          case conn.request_path do
            "/api/party/getPack" ->
              Req.Test.json(conn, %{"pack" => %{"id" => 7, "name" => "F"}})

            path ->
              send(test, {:called, path})
              Req.Test.json(conn, %{})
          end
        end)

      body = %{"seat_token" => token, "code" => "624949", "pack_id" => 7, "friend_id" => nil}
      assert response(invite(conn, body), 204)
      assert_received {:called, "/api/party/inviteAllFriendsToGame"}
    end

    test "only from a seat the player holds", %{conn: conn} do
      token = seated(conn, fn _ -> flunk("Sporcle was called") end)
      body = %{"seat_token" => token, "code" => "624949", "pack_id" => 7, "friend_id" => "xA1"}

      # Somebody else's credentials with this seat's token.
      assert %{"code" => "seat_not_found"} =
               conn
               |> as_player("otherPlayer")
               |> post(~p"/api/invites", body)
               |> json_response(404)

      assert %{"code" => "invalid_token"} =
               conn |> invite(%{body | "seat_token" => "forged"}) |> json_response(401)
    end

    test "a code or friend that can't be is refused first", %{conn: conn} do
      stub(fn _ -> flunk("Sporcle was called") end)
      body = %{"seat_token" => "t", "code" => "624949", "pack_id" => 7, "friend_id" => "xA1"}

      assert %{"code" => "invalid_code"} =
               conn |> invite(%{body | "code" => "12"}) |> json_response(400)

      assert %{"code" => "invalid_request"} =
               conn |> invite(%{body | "friend_id" => "a b"}) |> json_response(400)

      assert %{"code" => "invalid_request"} =
               conn |> invite(Map.delete(body, "pack_id")) |> json_response(400)
    end
  end
end
