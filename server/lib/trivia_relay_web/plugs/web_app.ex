defmodule TriviaRelayWeb.Plugs.WebApp do
  @moduledoc """
  Serves the built Flutter web app from `:web_dir` (`WEB_DIR`), next to the API it
  talks to, so the app's own origin is the relay and it needs no configuring.

  Every file is served with an ETag and `max-age=0, must-revalidate`: a client gets a
  cheap `304` or the new bytes, never a stale app shell. A `.br` copy beside a file is
  handed to clients that accept brotli. With `:web_dir` unset or missing, this does
  nothing. Copied from FazouraParty's `FazouraWeb.Plugs.WebApp`.
  """

  @behaviour Plug

  # Everything `flutter build web` emits that a browser may ask for.
  @served ~w(
    assets canvaskit icons
    apple-touch-icon.png build-manifest.json favicon.png flutter.js flutter_bootstrap.js
    flutter_service_worker.js index.html main.dart.js main.dart.wasm main.dart.mjs
    manifest.json version.json
  )

  # Deferred chunks dart2js emits (`main.dart.js_1.part.js`) carry a number, so they
  # cannot be listed: `:only` matches a whole first segment, `:only_matching` a prefix.
  @served_prefixes ~w(main.dart.js_)

  @cache_control "public, max-age=0, must-revalidate"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case dir() do
      nil -> conn
      dir -> serve(conn, dir)
    end
  end

  @doc "The directory the web app is served from, or nil when there isn't one."
  @spec dir() :: String.t() | nil
  def dir do
    case Application.get_env(:trivia_relay, :web_dir) do
      path when is_binary(path) -> if File.dir?(path), do: path
      _ -> nil
    end
  end

  defp serve(%{path_info: []} = conn, dir), do: conn |> protect() |> send_index(dir)

  defp serve(conn, dir) do
    Plug.Static.call(
      protect(conn),
      Plug.Static.init(
        at: "/",
        from: dir,
        only: @served,
        only_matching: @served_prefixes,
        brotli: true,
        cache_control_for_etags: @cache_control,
        cache_control_for_vsn_requests: @cache_control
      )
    )
  end

  # No other site may frame the app: a host's controls under somebody else's page are
  # a click away from moving a game on. A full CSP is left out on
  # purpose — Flutter's renderer needs `wasm-unsafe-eval` and inline bootstrap, and a
  # policy loose enough for that buys little — but framing is the one it can refuse.
  defp protect(conn) do
    Plug.Conn.merge_resp_headers(conn, [
      {"content-security-policy", "frame-ancestors 'none'"},
      {"x-frame-options", "DENY"},
      {"x-content-type-options", "nosniff"},
      {"referrer-policy", "no-referrer"}
    ])
  end

  # The app is a single page: "/" is the shell.
  defp send_index(conn, dir) do
    index = Path.join(dir, "index.html")

    if File.regular?(index) do
      conn
      |> Plug.Conn.put_resp_content_type("text/html")
      |> Plug.Conn.put_resp_header("cache-control", @cache_control)
      |> Plug.Conn.send_file(200, index)
      |> Plug.Conn.halt()
    else
      conn
    end
  end
end
