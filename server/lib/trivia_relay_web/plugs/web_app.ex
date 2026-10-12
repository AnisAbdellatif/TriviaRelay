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

  # An invite link (`/join/<code>`, protocol/PROTOCOL.md §3.8) is the app itself, which
  # reads the code from its address and offers to join. Only a code as games have them:
  # anything else under /join is nothing here.
  defp serve(%{path_info: ["join", code]} = conn, dir) do
    if invite_code?(code), do: conn |> protect() |> send_index(dir), else: conn
  end

  # The page's headers go only on what this serves: the API and /admin set their own.
  defp serve(conn, dir) do
    served =
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

    if served.halted, do: served, else: conn
  end

  # What the page may load, and that no other site may frame it: a host's controls under
  # somebody else's page are a click away from moving a game on.
  #
  # The Flutter app needs, beyond its own files (index.html loads flutter_bootstrap.js
  # from a file; there is no inline script):
  #   * `wasm-unsafe-eval`, to compile CanvasKit's WebAssembly (served locally,
  #     `--no-web-resources-cdn`);
  #   * inline styles: the engine writes its own <style> elements;
  #   * images from anywhere over https: pack and question pictures are <img> elements
  #     straight from Sporcle's hosts, and decoded ones become blob:/data: URLs;
  #   * fonts.gstatic.com, where the engine fetches Noto fallback fonts for glyphs the
  #     bundled fonts don't have (emoji, other scripts);
  #   * its relay: this origin, over https and over its socket (wss:, or ws: in
  #     development), named outright because older browsers don't count a socket as
  #     'self'.
  defp protect(conn) do
    Plug.Conn.merge_resp_headers(conn, [
      {"content-security-policy", csp()},
      {"x-frame-options", "DENY"},
      {"x-content-type-options", "nosniff"},
      {"referrer-policy", "no-referrer"}
    ])
  end

  @doc "The page's Content-Security-Policy."
  def csp do
    socket = TriviaRelayWeb.Endpoint.url() |> String.replace(~r/^http/, "ws")

    Enum.join(
      [
        "default-src 'self'",
        "script-src 'self' 'wasm-unsafe-eval'",
        "style-src 'self' 'unsafe-inline'",
        "img-src 'self' https: data: blob:",
        "font-src 'self' data: https://fonts.gstatic.com",
        "connect-src 'self' #{socket} https://fonts.gstatic.com",
        "worker-src 'self' blob:",
        "manifest-src 'self'",
        "object-src 'none'",
        "base-uri 'self'",
        "form-action 'none'",
        "frame-ancestors 'none'"
      ],
      "; "
    )
  end

  @doc "Whether `code` is a game code: 4 to 8 digits."
  def invite_code?(code), do: is_binary(code) and String.match?(code, ~r/\A\d{4,8}\z/)

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
