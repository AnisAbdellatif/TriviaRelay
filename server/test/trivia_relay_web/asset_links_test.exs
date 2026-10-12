defmodule TriviaRelayWeb.AssetLinksTest do
  # :android_cert_sha256 is global.
  use TriviaRelayWeb.ConnCase, async: false

  setup do
    on_exit(fn -> Application.delete_env(:trivia_relay, :android_cert_sha256) end)
  end

  @print "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"

  test "vouches for the released app signed with the configured key", %{conn: conn} do
    lower = @print |> String.downcase() |> String.replace(":", "")
    Application.put_env(:trivia_relay, :android_cert_sha256, [lower, "not-a-print", @print])

    assert [
             %{
               "relation" => ["delegate_permission/common.handle_all_urls"],
               "target" => %{
                 "namespace" => "android_app",
                 "package_name" => "com.triviarelay.app",
                 "sha256_cert_fingerprints" => [@print]
               }
             }
           ] = conn |> get("/.well-known/assetlinks.json") |> json_response(200)
  end

  test "is nothing when no key is configured", %{conn: conn} do
    assert conn |> get("/.well-known/assetlinks.json") |> response(404)

    Application.put_env(:trivia_relay, :android_cert_sha256, ["nope"])
    assert conn |> get("/.well-known/assetlinks.json") |> response(404)
  end
end
