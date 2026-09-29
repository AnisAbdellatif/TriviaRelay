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

  test "the shell and its files carry a full policy", %{conn: conn} do
    for path <- ["/", "/flutter_bootstrap.js"] do
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
end
