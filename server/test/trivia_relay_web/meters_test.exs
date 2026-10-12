defmodule TriviaRelayWeb.MetersTest do
  # The meters are global (one ETS table, one switch), so these run on their own.
  use TriviaRelayWeb.ConnCase, async: false

  alias TriviaRelay.RateLimit
  alias TriviaRelay.Sporcle.Cred
  alias TriviaRelayWeb.Meters

  setup do
    Application.put_env(:trivia_relay, :rate_limit_enabled, true)
    RateLimit.reset()

    on_exit(fn ->
      Application.put_env(:trivia_relay, :rate_limit_enabled, false)
      RateLimit.reset()
    end)
  end

  defp player(id \\ "p1") do
    %{"player_id" => id, "token" => "t0k3n", "device_id" => "0123456789abcdef"}
  end

  defp from(conn, ip), do: %{conn | remote_ip: ip}

  describe "logins" do
    defp login(conn, email) do
      conn
      |> put_req_header("origin", TriviaRelayWeb.Endpoint.url())
      # Each from its own address, so the per-address meter isn't what stops them.
      |> from({10, 0, 0, System.unique_integer([:positive]) |> rem(250)})
      |> post(~p"/api/login", %{"email" => email, "password" => "wrong"})
    end

    defp wrong_password do
      Req.Test.stub(TriviaRelay.Sporcle, fn conn ->
        case conn.request_path do
          "/login/" -> Req.Test.html(conn, "ok")
          "/auth/ajax/login.php" -> Req.Test.json(conn, %{"success" => false})
        end
      end)
    end

    test "an email that keeps failing is refused before Sporcle", %{conn: conn} do
      wrong_password()

      for _ <- 1..5, do: assert(json_response(login(conn, "Victim@x.com"), 401))

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      # However it is written.
      assert %{"code" => "rate_limited"} = json_response(login(conn, " victim@X.com"), 429)

      wrong_password()
      assert json_response(login(conn, "someone.else@x.com"), 401)
    end

    test "too many failures across the relay stop every login for a while", %{conn: conn} do
      wrong_password()

      for n <- 1..30, do: assert(json_response(login(conn, "u#{n}@x.com"), 401))

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      assert %{"code" => "rate_limited"} = json_response(login(conn, "fresh@x.com"), 429)
    end

    test "the email is never kept as it was written", %{conn: conn} do
      wrong_password()
      login(conn, "secret-person@example.com")

      refute :ets.tab2list(RateLimit) |> inspect() |> String.contains?("secret-person")
    end
  end

  describe "seats" do
    defp join(conn, player, ip \\ {10, 1, 0, 1}) do
      conn |> from(ip) |> post(~p"/api/seats", %{"code" => "624949", "player" => player})
    end

    test "joins are metered per Sporcle account, once Sporcle has answered for it", %{
      conn: conn
    } do
      {:ok, cred} = Cred.new(player())
      ip = "10.2.0.1"

      # A made-up token (Sporcle refuses the sign-in) spends nobody's allowance.
      for _ <- 1..25, do: Meters.seat_result(:join, cred, ip, {:error, {:http, 401, %{}}})
      assert Meters.seat_allowed(:join, cred, ip) == :ok

      for _ <- 1..20, do: Meters.seat_result(:join, cred, ip, {:ok, %{}})
      assert Meters.seat_allowed(:join, cred, ip) == {:error, :rate_limited}

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      assert %{"code" => "rate_limited"} = json_response(join(conn, player(), {10, 3, 0, 1}), 429)

      {:ok, other} = Cred.new(player("p2"))
      assert Meters.seat_allowed(:join, other, ip) == :ok
    end

    test "refused joins (wrong codes) are metered tightly per account", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{"error" => "Game not found"}))

      for n <- 1..10, do: assert(json_response(join(conn, player(), {10, 6, 0, n}), 409))

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      assert %{"code" => "rate_limited"} = json_response(join(conn, player(), {10, 7, 0, 1}), 429)
    end

    test "a game that exists but wants a Party Popper is no guess", %{conn: conn} do
      Req.Test.stub(
        TriviaRelay.Sporcle,
        &Req.Test.json(&1, %{"denied" => %{"code" => "BuyPopper"}, "popper_count" => 0})
      )

      for n <- 1..12 do
        assert %{"code" => "insufficient_poppers"} =
                 json_response(join(conn, player(), {10, 9, 0, n}), 409)
      end
    end

    test "refused joins are metered per address, across accounts", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{"error" => "Game not found"}))

      for n <- 1..10, do: assert(json_response(join(conn, player("a#{n}")), 409))

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      assert %{"code" => "rate_limited"} = json_response(join(conn, player("fresh")), 429)
    end

    test "an IPv6 /48 can't spread code guesses over its /64s", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{"error" => "Game not found"}))

      # Ten to each of four /64s is the /48's forty.
      for net <- 1..4, n <- 1..10 do
        ip = {0x2001, 0xDB8, 7, net, 0, 0, 0, n}
        assert json_response(join(conn, player("a#{net}-#{n}"), ip), 409)
      end

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      ip = {0x2001, 0xDB8, 7, 99, 0, 0, 0, 1}
      assert %{"code" => "rate_limited"} = json_response(join(conn, player("new"), ip), 429)
    end

    test "creating games is metered per Sporcle account", %{conn: conn} do
      {:ok, cred} = Cred.new(player())
      for _ <- 1..10, do: Meters.seat_result(:host, cred, "10.8.0.1", {:ok, %{}})

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)

      conn =
        post(conn, ~p"/api/seats/host", %{
          "pack_id" => 1,
          "options" => %{
            "questions_per_game" => 5,
            "question_seconds" => 15,
            "audience" => "private"
          },
          "player" => player()
        })

      assert %{"code" => "rate_limited"} = json_response(conn, 429)
    end
  end

  describe "what reaches other people" do
    defp as_player(conn, id, ip) do
      conn
      |> from(ip)
      |> put_req_header("x-player-id", id)
      |> put_req_header("x-player-token", "t0k3n")
      |> put_req_header("x-device-id", "0123456789abcdef")
    end

    defp report(conn, id, ip) do
      conn
      |> as_player(id, ip)
      |> post(~p"/api/packs/1/report", %{"reason" => "spam", "details" => "ads"})
    end

    test "reports are metered per Sporcle account, across addresses", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{}))

      for n <- 1..10, do: assert(response(report(conn, "p1", {10, 11, 0, n}), 204))

      Req.Test.stub(TriviaRelay.Sporcle, fn _ -> flunk("Sporcle was called") end)
      assert %{"code" => "rate_limited"} = json_response(report(conn, "p1", {10, 12, 0, 1}), 429)
    end

    test "reports are metered per address too", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{}))

      for n <- 1..5, do: assert(response(report(conn, "a#{n}", {10, 13, 0, 1}), 204))
      assert %{"code" => "rate_limited"} = json_response(report(conn, "b", {10, 13, 0, 1}), 429)
    end

    test "inviting everybody is metered per account, and apart from one by one" do
      {:ok, cred} = Cred.new(player())
      for _ <- 1..3, do: Meters.account_result(:invite_all, cred, {:ok, %{}})

      assert Meters.account_allowed(:invite_all, cred) == {:error, :rate_limited}
      assert Meters.account_allowed(:invite, cred) == :ok

      # A made-up token spends nothing.
      {:ok, other} = Cred.new(player("p2"))
      for _ <- 1..5, do: Meters.account_result(:invite_all, other, {:error, {:http, 403, %{}}})
      assert Meters.account_allowed(:invite_all, other) == :ok
    end
  end

  describe "the per-address meter" do
    test "counts an IPv6 caller's /48 as well as its /64", %{conn: conn} do
      Req.Test.stub(TriviaRelay.Sporcle, &Req.Test.json(&1, %{"data" => %{"packs" => []}}))

      get_from = fn ip ->
        conn
        |> from(ip)
        |> put_req_header("x-player-id", "p1")
        |> put_req_header("x-player-token", "t")
        |> put_req_header("x-device-id", "0123456789abcdef")
        |> get(~p"/api/packs?q=x")
      end

      # 60 a minute per /64, 240 per /48: five /64s of one /48 run out on the fifth.
      for net <- 1..4,
          _ <- 1..60,
          do: assert(json_response(get_from.({0x2001, 0xDB8, 9, net, 0, 0, 0, 1}), 200))

      assert %{"code" => "rate_limited"} =
               json_response(get_from.({0x2001, 0xDB8, 9, 5, 0, 0, 0, 1}), 429)
    end
  end
end
