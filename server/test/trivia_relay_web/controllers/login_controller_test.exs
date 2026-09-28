defmodule TriviaRelayWeb.LoginControllerTest do
  use TriviaRelayWeb.ConnCase, async: true

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
end
