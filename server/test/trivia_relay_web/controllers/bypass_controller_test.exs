defmodule TriviaRelayWeb.BypassControllerTest do
  use TriviaRelayWeb.ConnCase, async: false

  alias TriviaRelay.Bypass
  alias TriviaRelay.Seats.Intents

  setup do
    Application.put_env(:trivia_relay, :admin_password, "test-admin")
    on_exit(fn -> Application.delete_env(:trivia_relay, :admin_password) end)
  end

  defp redeem(conn, code) do
    post(conn, "/api/bypass/redeem", %{code: code, device_id: "device"})
  end

  defp check(conn, bearer) do
    conn |> put_req_header("x-bypass-token", bearer) |> get("/api/bypass/check")
  end

  test "a redeemed bearer checks good until its code is deleted", %{conn: conn} do
    {:ok, code} = Bypass.create_code()
    %{"bearer" => bearer} = conn |> redeem(code) |> json_response(200)

    assert build_conn() |> check(bearer) |> response(204)

    Bypass.delete_code(code)
    assert %{"code" => "bypass_revoked"} = build_conn() |> check(bearer) |> json_response(403)
  end

  test "a check without a bearer is revoked", %{conn: conn} do
    assert %{"code" => "bypass_revoked"} = conn |> get("/api/bypass/check") |> json_response(403)
  end

  test "redeem errors carry the relay's codes", %{conn: conn} do
    {:ok, code} = Bypass.create_code()
    redeem(conn, code)

    assert %{"code" => "already_used"} = build_conn() |> redeem(code) |> json_response(409)
    assert %{"code" => "not_found"} = build_conn() |> redeem("nope") |> json_response(404)
  end

  test "a bypass intent with a revoked bearer says so" do
    {:ok, code} = Bypass.create_code()
    {:ok, bearer} = Bypass.redeem(code, "device")
    Bypass.delete_code(code)

    s = TriviaRelay.Replay.fresh(:lobby)

    assert {:error, "bypass_revoked"} =
             Intents.handle(s, "claim_host", %{"bypass_token" => bearer})
  end
end
