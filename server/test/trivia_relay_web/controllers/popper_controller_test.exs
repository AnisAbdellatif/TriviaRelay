defmodule TriviaRelayWeb.PopperControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  defp as_player(conn) do
    conn
    |> put_req_header("x-player-id", "p1")
    |> put_req_header("x-player-token", "t0k3n")
    |> put_req_header("x-device-id", "0123456789abcdef")
  end

  test "claims the poppers earned back and says how many there are", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/api/party/claimPoppers"
      assert Plug.Conn.get_req_header(conn, "x-sporcle-player") == ["p1"]
      Req.Test.json(conn, %{"popper_count" => 4, "popper_last_claim" => 1_790_000_000})
    end)

    assert %{"poppers" => 4, "last_claim" => 1_790_000_000_000} =
             conn |> as_player() |> post(~p"/api/poppers/claim") |> json_response(200)
  end

  test "an answer without a count says it doesn't know", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{"popper_count" => "lots"}))

    assert %{"poppers" => nil, "last_claim" => nil} =
             conn |> as_player() |> post(~p"/api/poppers/claim") |> json_response(200)
  end

  test "an expired sign-in is told as one", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, &Plug.Conn.send_resp(&1, 401, ""))

    assert %{"code" => "sporcle_auth"} =
             conn |> as_player() |> post(~p"/api/poppers/claim") |> json_response(401)
  end
end
