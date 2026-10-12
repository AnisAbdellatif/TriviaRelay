defmodule TriviaRelayWeb.NameControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  defp check(conn, body) do
    conn
    |> put_req_header("x-player-id", "p1")
    |> put_req_header("x-player-token", "t0k3n")
    |> put_req_header("x-device-id", "0123456789abcdef")
    |> post(~p"/api/names/check", body)
  end

  test "asks Sporcle about the name as the relay would pass it on", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      assert conn.request_path == "/api/party/getHandleHasBadWords"
      assert Plug.Conn.fetch_query_params(conn).query_params == %{"handle" => "Quiz Wiz"}
      Req.Test.json(conn, %{"handle_has_bad_words" => false})
    end)

    assert %{"name" => "Quiz Wiz", "allowed" => true} =
             conn |> check(%{"name" => "  Quiz \u200BWiz "}) |> json_response(200)
  end

  test "says when Sporcle won't have it", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{"handle_has_bad_words" => true}))
    assert %{"allowed" => false} = conn |> check(%{"name" => "rude"}) |> json_response(200)
  end

  test "a name with nothing left in it is refused first", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)

    for body <- [%{"name" => " \u202E "}, %{"name" => 5}, %{}] do
      assert %{"code" => "invalid_request"} = conn |> check(body) |> json_response(400)
    end
  end
end
