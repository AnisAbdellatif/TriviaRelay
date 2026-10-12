defmodule TriviaRelayWeb.LoginControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

  # Only a page of the relay's own origin may log in (TriviaRelayWeb.Plugs.SameOrigin).
  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "origin", TriviaRelayWeb.Endpoint.url())}
  end

  # The two-step login the official app uses (TriviaRelay.Sporcle.Login):
  # prime /login/?party_udid=, then POST login.php, which returns the party token.
  defp sporcle(conn, ok? \\ true) do
    case {conn.method, conn.request_path} do
      {"GET", "/login/"} ->
        assert conn
               |> Plug.Conn.fetch_query_params()
               |> Map.get(:query_params)
               |> Map.has_key?("party_udid")

        conn
        |> Plug.Conn.put_resp_header("set-cookie", "sporid=xAc71a08as%7Csig; Path=/")
        |> Req.Test.html("<html>login</html>")

      {"POST", "/auth/ajax/login.php"} ->
        assert {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert URI.decode_query(body)["passwd"] == "secret"
        # The primed session's cookie is sent back on the login POST.
        assert ["sporid=" <> _] = Plug.Conn.get_req_header(conn, "cookie")

        if ok? do
          Req.Test.json(conn, %{
            "success" => true,
            "logged_in" => true,
            "user_id" => "xAc71a08as",
            "handle" => "Anis-Abdellatif",
            "token" => String.duplicate("a", 64)
          })
        else
          Req.Test.json(conn, %{"success" => false, "logged_in" => false})
        end
    end
  end

  test "primes party context, then returns the party credentials", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, &sporcle/1)
    conn = post(conn, ~p"/api/login", %{"email" => "a@b.c", "password" => "secret"})

    assert %{"player_id" => "xAc71a08as", "handle" => "Anis-Abdellatif", "token" => token} =
             json_response(conn, 200)

    assert String.length(token) == 64
  end

  test "a wrong password is login_failed", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, &sporcle(&1, false))
    conn = post(conn, ~p"/api/login", %{"email" => "a@b.c", "password" => "secret"})
    assert %{"code" => "login_failed"} = json_response(conn, 401)
  end

  test "a login with no party token is not mistaken for success", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      case conn.request_path do
        "/login/" -> Req.Test.html(conn, "ok")
        "/auth/ajax/login.php" -> Req.Test.json(conn, %{"success" => true, "logged_in" => true})
      end
    end)

    conn = post(conn, ~p"/api/login", %{"email" => "a@b.c", "password" => "secret"})
    assert %{"code" => "sporcle_unavailable"} = json_response(conn, 502)
  end

  describe "who may log in" do
    setup do
      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      :ok
    end

    defp attempt(conn, body \\ %{"email" => "a@b.c", "password" => "secret"}),
      do: post(conn, ~p"/api/login", body)

    test "only a page of the relay's own origin", %{conn: conn} do
      for origin <- ["https://evil.example", "null", "http://localhost:9999"] do
        conn = conn |> put_req_header("origin", origin) |> attempt()
        assert %{"code" => "forbidden_origin"} = json_response(conn, 403), origin
      end
    end

    test "never without an origin, as no browser would send it", %{conn: conn} do
      conn = conn |> delete_req_header("origin") |> attempt()
      assert %{"code" => "forbidden_origin"} = json_response(conn, 403)
    end

    test "a device id the app wouldn't make is refused", %{conn: conn} do
      body = %{"email" => "a@b.c", "password" => "secret", "device_id" => "../x?y=1"}
      assert %{"code" => "invalid_request"} = conn |> attempt(body) |> json_response(400)
    end

    test "an email or password of no sensible length is refused", %{conn: conn} do
      long = String.duplicate("a", 300)

      for body <- [%{"email" => long, "password" => "x"}, %{"email" => "a@b.c", "password" => ""}] do
        assert %{"code" => "invalid_request"} = conn |> attempt(body) |> json_response(400)
      end
    end
  end

  test "the device id goes to Sporcle as a query parameter", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
      case conn.request_path do
        "/login/" ->
          assert conn.query_string == "party_udid=0123456789abcdef"
          Req.Test.html(conn, "ok")

        "/auth/ajax/login.php" ->
          Req.Test.json(conn, %{"success" => false})
      end
    end)

    body = %{"email" => "a@b.c", "password" => "x", "device_id" => "0123456789abcdef"}
    assert json_response(post(conn, ~p"/api/login", body), 401)
  end

  test "a failure is logged by its kind, never with what was sent", %{conn: conn} do
    Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.transport_error(&1, :econnrefused))

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        conn = post(conn, ~p"/api/login", %{"email" => "who@b.c", "password" => "hunter2"})
        assert %{"code" => "sporcle_unavailable"} = json_response(conn, 502)
      end)

    assert log =~ "Sporcle login failed at prime: Req.TransportError :econnrefused"
    refute log =~ "who@b.c"
    refute log =~ "party_udid"
  end
end
