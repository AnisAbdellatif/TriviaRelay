defmodule TriviaRelay.Sporcle.Identity do
  @moduledoc """
  What the relay says about itself to Sporcle: the Party app's key, version and
  user agents (`sporcle_scraper/sporcle/config.py`), and the player a login
  message describes. Everything version-pinned lives here, so a Sporcle update
  is one file to change.

  The key is Sporcle's, from its own app, so it isn't kept in this repository: it comes
  from `SPORCLE_API_KEY` (`server/.env.example` says what it is and where to find it).
  """

  @version "1.5.15.297"

  def api_key, do: Application.fetch_env!(:trivia_relay, :sporcle_api_key)
  def bundle, do: "com.sporcle.party"
  def version, do: @version
  def user_agent_api, do: "party/#{@version} Mozilla/5.0 (Linux; Android 17) Mobile Safari/537.36"
  def user_agent_ws, do: "okhttp/4.9.2"

  @doc "The id the game server knows a player by: the REST id, prefixed."
  def sporcle_id(cred), do: "sporcle_id//" <> cred.player_id

  @doc """
  The player JSON of a GameLift login. The REST API takes the bare player id;
  the game server wants it prefixed with `sporcle_id//`.

  A host's login carries the game options again: the server takes them from
  here, not from `createGame` (the official app sends both).
  """
  def player(cred, host?, options \\ nil)

  def player(cred, true, options) when is_map(options) do
    cred
    |> player(true, nil)
    |> Map.merge(%{"gameOptions" => options, "spectate" => Map.get(options, "SPECTATE", false)})
  end

  def player(cred, host?, _options) do
    %{
      "isHost" => host?,
      "teamName" => cred.handle,
      "mascotType" => "none",
      "mascotCustomImageUrl" => "",
      "hatType" => "None",
      "clientVersion" => @version,
      "sporcleHandle" => cred.handle,
      "platform" => %{
        "os" => "android",
        "brand" => "google",
        "manufacturer" => "Google",
        "systemVersion" => "17"
      },
      "playerId" => sporcle_id(cred),
      "deviceId" => cred.device_id
    }
  end
end
