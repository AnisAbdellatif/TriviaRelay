defmodule TriviaRelayWeb.PackControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  test "searches Sporcle's packs with the caller's credentials, from headers", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      assert conn.request_path == "/api/party/searchPacks"

      assert %{"searchText" => "flags", "page" => "1"} =
               Plug.Conn.fetch_query_params(conn).query_params

      assert Plug.Conn.get_req_header(conn, "x-sporcle-player") == ["p1"]

      Req.Test.json(conn, %{
        "data" => %{
          "packs" => [
            %{
              "id" => 7,
              "name" => "Flags",
              "img_src" => "https://x/7",
              "num_questions" => 169,
              "has_images" => false
            }
          ]
        }
      })
    end)

    conn =
      conn
      |> put_req_header("x-player-id", "p1")
      |> put_req_header("x-player-token", "t")
      |> put_req_header("x-device-id", "d")
      |> get(~p"/api/packs?q=flags&page=1")

    assert %{
             "packs" => [
               %{
                 "id" => 7,
                 "name" => "Flags",
                 "image_url" => "https://x/7",
                 "num_questions" => 169
               }
             ]
           } =
             json_response(conn, 200)
  end

  describe "browsing a list" do
    defp browse(conn, path) do
      conn
      |> put_req_header("x-player-id", "p1")
      |> put_req_header("x-player-token", "t")
      |> put_req_header("x-device-id", "d")
      |> get(path)
    end

    test "asks Sporcle for the list's type and sort, as the official app does", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
        params = Plug.Conn.fetch_query_params(conn).query_params
        assert params["searchText"] == ""

        assert Jason.decode!(params["filters"]) == %{
                 "type" => "mostPopular",
                 "sort" => "play_count"
               }

        assert params["page"] == "2"

        Req.Test.json(conn, %{
          "data" => %{"packs" => [%{"id" => 1, "name" => "A", "img_src" => ""}]}
        })
      end)

      assert %{"packs" => [%{"id" => 1, "image_url" => nil}], "next_page" => 3} =
               conn |> browse(~p"/api/packs?list=popular&page=2") |> json_response(200)
    end

    test "an empty page ends the list", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{"data" => %{"packs" => []}}))

      assert %{"packs" => [], "next_page" => nil} =
               conn |> browse(~p"/api/packs?list=fresh&page=4") |> json_response(200)
    end

    test "a list that doesn't exist never reaches Sporcle", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)

      assert %{"code" => "invalid_list"} =
               conn |> browse(~p"/api/packs?list=secret") |> json_response(400)
    end
  end

  test "needs credentials", %{conn: conn} do
    assert %{"code" => "invalid_player"} = conn |> get(~p"/api/packs?q=x") |> json_response(400)
  end
end
