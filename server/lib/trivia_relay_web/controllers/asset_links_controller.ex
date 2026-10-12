defmodule TriviaRelayWeb.AssetLinksController do
  @moduledoc """
  `GET /.well-known/assetlinks.json`: Android's Digital Asset Links statement, which lets
  the released app open this relay's invite links (`https://<relay>/join/<code>`) itself
  instead of the browser (`protocol/PROTOCOL.md` §3.8, since 1.2).

  Android checks it against the certificate the installed app was signed with, so the
  deployment names the release key's SHA-256 fingerprint(s): `ANDROID_CERT_SHA256`,
  comma-separated (`deploy/README.md`). Without one there is nothing to vouch for, and
  this is a 404: links then open the web app, which works as well.
  """

  use TriviaRelayWeb, :controller

  # The released app (app/android/app/build.gradle.kts). Development builds carry a
  # `.dev` suffix and a debug key, and are never vouched for.
  @package "com.triviarelay.app"

  def show(conn, _params) do
    case fingerprints() do
      [] ->
        conn |> put_resp_content_type("application/json") |> send_resp(:not_found, "[]")

      prints ->
        conn
        |> put_resp_header("cache-control", "public, max-age=3600")
        |> json([
          %{
            relation: ["delegate_permission/common.handle_all_urls"],
            target: %{
              namespace: "android_app",
              package_name: @package,
              sha256_cert_fingerprints: prints
            }
          }
        ])
    end
  end

  @doc """
  The configured fingerprints, as Android writes them (`AB:CD:…`, 32 bytes in upper-case
  hex). Anything that isn't one is left out.
  """
  def fingerprints do
    :trivia_relay
    |> Application.get_env(:android_cert_sha256, [])
    |> List.wrap()
    |> Enum.flat_map(&fingerprint/1)
    |> Enum.uniq()
  end

  defp fingerprint(value) when is_binary(value) do
    hex = value |> String.replace(":", "") |> String.trim() |> String.upcase()

    if String.match?(hex, ~r/\A[0-9A-F]{64}\z/) do
      [hex |> String.to_charlist() |> Enum.chunk_every(2) |> Enum.map_join(":", &to_string/1)]
    else
      []
    end
  end

  defp fingerprint(_), do: []
end
