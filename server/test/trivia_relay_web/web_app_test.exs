defmodule TriviaRelayWeb.WebAppTest do
  # :web_dir is global.
  use TriviaRelayWeb.ConnCase, async: false

  @moduletag :tmp_dir

  setup %{tmp_dir: dir} do
    File.write!(Path.join(dir, "index.html"), "<html></html>")
    File.write!(Path.join(dir, "flutter_bootstrap.js"), "")
    Application.put_env(:trivia_relay, :web_dir, dir)
    on_exit(fn -> Application.delete_env(:trivia_relay, :web_dir) end)
  end

  defp policy(conn) do
    [csp] = get_resp_header(conn, "content-security-policy")

    for directive <- String.split(csp, ";"), into: %{} do
      [name | values] = directive |> String.trim() |> String.split(" ")
      {name, values}
    end
  end

  test "an invite link is the app, for a game code only", %{conn: conn} do
    conn = get(conn, "/join/624949")
    assert response(conn, 200) == "<html></html>"
    assert policy(conn)["frame-ancestors"] == ["'none'"]

    for path <- ["/join/12", "/join/12345678901", "/join/abcd", "/join/1234/x"] do
      assert build_conn() |> get(path) |> response(404)
    end
  end

  test "the shell and its files carry a full policy", %{conn: conn} do
    for path <- ["/", "/join/1234", "/flutter_bootstrap.js"] do
      conn = get(conn, path)
      assert conn.status == 200
      policy = policy(conn)

      assert policy["default-src"] == ["'self'"]
      # No inline or eval'd script: only the relay's own files, and WebAssembly.
      assert policy["script-src"] == ["'self'", "'wasm-unsafe-eval'"]
      assert policy["object-src"] == ["'none'"]
      assert policy["frame-ancestors"] == ["'none'"]
      assert policy["base-uri"] == ["'self'"]
      # The relay itself, over its socket too; Sporcle's pictures; fallback fonts.
      socket = String.replace(TriviaRelayWeb.Endpoint.url(), "http://", "ws://")
      assert socket in policy["connect-src"]
      assert "https:" in policy["img-src"]
      assert "https://fonts.gstatic.com" in policy["font-src"]
      assert get_resp_header(conn, "x-frame-options") == ["DENY"]
    end
  end

  # The page's `form-action 'none'` would stop the admin panel's forms.
  test "what the app doesn't serve gets none of its headers", %{conn: conn} do
    conn = get(conn, "/admin/login")
    refute policy(conn)["form-action"]
    assert get_resp_header(conn, "x-frame-options") == []
  end
end
