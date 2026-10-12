defmodule TriviaRelayWeb.PackActionControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  defp as_player(conn) do
    conn
    |> put_req_header("x-player-id", "p1")
    |> put_req_header("x-player-token", "t0k3n")
    |> put_req_header("x-device-id", "0123456789abcdef")
  end

  defp stub(fun), do: Req.Test.stub(TriviaRelay.Sporcle, fun)

  defp body(conn) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    {Jason.decode!(body), conn}
  end

  describe "bookmarks" do
    test "sends the pack's state before the tap, as the official app does", %{conn: conn} do
      test = self()

      stub(fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/party/bookmarkPack"
        assert Plug.Conn.get_req_header(conn, "x-sporcle-token") == ["t0k3n"]
        {body, conn} = body(conn)
        send(test, {:sent, body})
        Req.Test.json(conn, %{"success" => true})
      end)

      assert %{"bookmarked" => true} =
               conn
               |> as_player()
               |> post(~p"/api/packs/156070/bookmark", %{"bookmarked" => true})
               |> json_response(200)

      assert_received {:sent, %{"pack_id" => 156_070, "bookmarked" => false}}

      assert %{"bookmarked" => false} =
               conn
               |> as_player()
               |> post(~p"/api/packs/156070/bookmark", %{"bookmarked" => false})
               |> json_response(200)

      assert_received {:sent, %{"pack_id" => 156_070, "bookmarked" => true}}
    end

    test "a refusal of Sporcle's own is told as one, not as an outage", %{conn: conn} do
      stub(&Plug.Conn.send_resp(&1, 400, ~s({"error":"limit"})))

      assert %{"code" => "sporcle_refused"} =
               conn
               |> as_player()
               |> post(~p"/api/packs/1/bookmark", %{"bookmarked" => true})
               |> json_response(409)
    end

    test "needs a pack id, a flag and credentials, before Sporcle is asked", %{conn: conn} do
      stub(fn _ -> flunk("Sporcle was called") end)

      assert %{"code" => "pack_not_found"} =
               conn
               |> as_player()
               |> post("/api/packs/abc/bookmark", %{"bookmarked" => true})
               |> json_response(404)

      assert %{"code" => "invalid_request"} =
               conn
               |> as_player()
               |> post(~p"/api/packs/1/bookmark", %{"bookmarked" => "yes"})
               |> json_response(400)

      assert %{"code" => "invalid_player"} =
               conn
               |> post(~p"/api/packs/1/bookmark", %{"bookmarked" => true})
               |> json_response(400)
    end
  end

  test "subscribing sends its flag the same way", %{conn: conn} do
    test = self()

    stub(fn conn ->
      assert conn.request_path == "/api/party/subscribePack"
      {body, conn} = body(conn)
      send(test, {:sent, body})
      Req.Test.json(conn, %{})
    end)

    assert %{"subscribed" => true} =
             conn
             |> as_player()
             |> post(~p"/api/packs/7/subscribe", %{"subscribed" => true})
             |> json_response(200)

    assert_received {:sent, %{"pack_id" => 7, "subscribed" => false}}
  end

  describe "reports" do
    test "go to Sporcle with the reason and the player's words", %{conn: conn} do
      test = self()

      stub(fn conn ->
        assert conn.request_path == "/api/party/reportPack"
        {body, conn} = body(conn)
        send(test, {:sent, body})
        Req.Test.json(conn, %{})
      end)

      conn =
        conn
        |> as_player()
        |> post(~p"/api/packs/42/report", %{
          "reason" => "inaccurate",
          "details" => "  Question 3's answer\u202E is wrong.\n "
        })

      assert response(conn, 204)

      assert_received {:sent,
                       %{
                         "pack_id" => 42,
                         "reason" => "inaccurate",
                         "extraInfoText" => "Question 3's answer  is wrong."
                       }}
    end

    test "need one of the reasons offered and some words, at most 200", %{conn: conn} do
      stub(fn _ -> flunk("Sporcle was called") end)

      for body <- [
            %{"reason" => "boring", "details" => "x"},
            %{"reason" => "spam", "details" => "   "},
            %{"reason" => "spam", "details" => String.duplicate("a", 201)},
            %{"reason" => "spam"}
          ] do
        assert %{"code" => "invalid_request"} =
                 conn
                 |> as_player()
                 |> post(~p"/api/packs/42/report", body)
                 |> json_response(400)
      end
    end
  end
end
