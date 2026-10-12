defmodule TriviaRelayWeb.AdminController do
  @moduledoc """
  Web admin panel for bypass code management (`/admin`).
  Requires `ADMIN_PASSWORD` to be set; session-authenticated.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Bypass

  def index(conn, _params) do
    if authed?(conn) do
      codes = Bypass.list_codes()
      html(conn, dashboard_html(codes))
    else
      redirect(conn, to: "/admin/login")
    end
  end

  def login_form(conn, params) do
    if authed?(conn) do
      redirect(conn, to: "/admin")
    else
      html(conn, login_html(params["error"]))
    end
  end

  def login(conn, %{"password" => pw}) do
    secret = Application.get_env(:trivia_relay, :admin_password)

    if secret && Plug.Crypto.secure_compare(secret, pw) do
      conn
      |> put_session(:admin, true)
      |> configure_session(renew: true)
      |> redirect(to: "/admin")
    else
      redirect(conn, to: "/admin/login?error=1")
    end
  end

  def login(conn, _params), do: redirect(conn, to: "/admin/login?error=1")

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/admin/login")
  end

  def create_code(conn, _params) do
    if authed?(conn) do
      case Bypass.create_code() do
        {:ok, _code} -> redirect(conn, to: "/admin")
        :disabled -> conn |> put_status(503) |> html(disabled_html())
      end
    else
      conn |> put_status(401) |> redirect(to: "/admin/login") |> halt()
    end
  end

  def delete_code(conn, %{"code" => code}) when is_binary(code) do
    if authed?(conn) do
      Bypass.delete_code(code)
      redirect(conn, to: "/admin")
    else
      redirect(conn, to: "/admin/login")
    end
  end

  def delete_code(conn, _params), do: redirect(conn, to: "/admin")

  defp authed?(conn), do: get_session(conn, :admin) == true

  ## HTML

  defp page(title, body) do
    csrf = Plug.CSRFProtection.get_csrf_token()

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>#{title} — Trivia Relay Admin</title>
      <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0 }
        body { font-family: system-ui, sans-serif; background: #0f1117; color: #e4e6ef;
               min-height: 100vh; padding: 2rem 1rem }
        h1 { font-size: 1.4rem; font-weight: 700; margin-bottom: 1.5rem; color: #fff }
        h2 { font-size: 1rem; font-weight: 600; margin-bottom: 0.75rem; color: #ccc }
        .card { background: #1a1d27; border: 1px solid #2a2d3a; border-radius: 12px;
                padding: 1.5rem; max-width: 680px; margin: 0 auto 1.5rem }
        label { display: block; font-size: 0.8rem; color: #999; margin-bottom: 0.4rem;
                text-transform: uppercase; letter-spacing: .05em }
        input[type=password], input[type=text] {
          width: 100%; padding: 0.6rem 0.8rem; background: #0f1117;
          border: 1px solid #2a2d3a; border-radius: 8px; color: #e4e6ef;
          font-size: 0.95rem; outline: none }
        input:focus { border-color: #e84c4c }
        .btn { display: inline-block; padding: 0.55rem 1.2rem; border-radius: 8px;
               border: none; font-size: 0.9rem; font-weight: 600; cursor: pointer;
               text-decoration: none }
        .btn-primary { background: #e84c4c; color: #fff }
        .btn-secondary { background: #2a2d3a; color: #ccc }
        .btn-small { padding: 0.35rem 0.8rem; font-size: 0.8rem }
        .error { color: #e84c4c; font-size: 0.85rem; margin-top: 0.5rem }
        table { width: 100%; border-collapse: collapse; font-size: 0.88rem }
        th { text-align: left; color: #888; font-weight: 500; padding: 0.4rem 0.6rem;
             border-bottom: 1px solid #2a2d3a }
        td { padding: 0.5rem 0.6rem; border-bottom: 1px solid #1e2130;
             font-family: monospace }
        td.status-used { color: #666 }
        td.status-unused { color: #4caf7d; font-weight: 600 }
        .row-used td { opacity: 0.5 }
        .flex { display: flex; align-items: center; gap: 0.75rem }
        nav { max-width: 680px; margin: 0 auto 1rem;
              display: flex; justify-content: space-between; align-items: center }
        nav a { color: #888; font-size: 0.85rem; text-decoration: none }
      </style>
    </head>
    <body>
      <input type="hidden" id="csrf" value="#{csrf}">
      #{body}
    </body>
    </html>
    """
  end

  defp login_html(error) do
    error_msg = if error, do: ~s(<p class="error">Wrong password.</p>), else: ""

    page("Sign in", """
    <div class="card" style="margin-top: 20vh">
      <h1>Trivia Relay Admin</h1>
      <form method="post" action="/admin/login">
        <input type="hidden" name="_csrf_token" value="#{Plug.CSRFProtection.get_csrf_token()}">
        <label for="password">Admin password</label>
        <input type="password" id="password" name="password" autofocus required>
        #{error_msg}
        <div style="margin-top: 1rem">
          <button type="submit" class="btn btn-primary">Sign in</button>
        </div>
      </form>
    </div>
    """)
  end

  defp dashboard_html(codes) do
    csrf = Plug.CSRFProtection.get_csrf_token()

    rows =
      Enum.map_join(codes, "\n", fn {code, used, created_at_ms} ->
        created = format_ts(created_at_ms)
        row_class = if used, do: "row-used", else: ""
        status_class = if used, do: "status-used", else: "status-unused"
        status_text = if used, do: "used", else: "unused"

        """
        <tr class="#{row_class}">
          <td>#{code}</td>
          <td class="#{status_class}">#{status_text}</td>
          <td style="font-family: system-ui; font-size: 0.8rem">#{created}</td>
          <td style="text-align: right">
            <form method="post" action="/admin/codes/delete"
                  onsubmit="return confirm('Delete code #{code}?')">
              <input type="hidden" name="_csrf_token" value="#{csrf}">
              <input type="hidden" name="code" value="#{code}">
              <button type="submit" class="btn btn-secondary btn-small">Delete</button>
            </form>
          </td>
        </tr>
        """
      end)

    table =
      if codes == [] do
        "<p style='color: #666; font-size: 0.9rem'>No codes yet.</p>"
      else
        """
        <table>
          <thead><tr><th>Code</th><th>Status</th><th>Created</th><th></th></tr></thead>
          <tbody>#{rows}</tbody>
        </table>
        """
      end

    page("Dashboard", """
    <nav>
      <span style="color: #fff; font-weight: 700">Trivia Relay Admin</span>
      <form method="post" action="/admin/logout" style="display:inline">
        <input type="hidden" name="_csrf_token" value="#{csrf}">
        <button type="submit" class="btn btn-secondary btn-small">Sign out</button>
      </form>
    </nav>
    <div class="card">
      <div class="flex" style="margin-bottom: 1.25rem">
        <h1 style="margin: 0">Bypass codes</h1>
        <form method="post" action="/admin/codes">
          <input type="hidden" name="_csrf_token" value="#{csrf}">
          <button type="submit" class="btn btn-primary btn-small">+ Generate code</button>
        </form>
      </div>
      #{table}
    </div>
    """)
  end

  defp disabled_html do
    page("Disabled", """
    <div class="card" style="margin-top: 20vh">
      <h1>Bypass disabled</h1>
      <p style="color: #888">Set <code>ADMIN_PASSWORD</code> on the relay to enable it.</p>
    </div>
    """)
  end

  defp format_ts(ms) do
    ms
    |> System.convert_time_unit(:millisecond, :second)
    |> DateTime.from_unix!()
    |> Calendar.strftime("%Y-%m-%d %H:%M UTC")
  end
end
