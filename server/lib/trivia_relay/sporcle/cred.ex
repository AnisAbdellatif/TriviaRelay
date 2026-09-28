defmodule TriviaRelay.Sporcle.Cred do
  @moduledoc """
  One Sporcle account's Party credentials: the bare player id, the session token,
  a device id and the handle other players see.

  In the relay these arrive from the phone with each request (`new/1`) and are never
  kept. For the spike console they are read from `creds/<name>.json`, the output of
  the scraper's `sporcle token <SLOT>` (`load/1`).
  """

  @enforce_keys [:player_id, :token, :device_id, :handle]
  defstruct @enforce_keys

  # The scraper's default X-UDID, used when a credential file names none.
  @default_device_id "956aa24a2296d663"

  @doc "From a phone's request: `player_id`, `token`, `device_id` and `handle`."
  def new(%{} = p) do
    with id when is_binary(id) and id != "" <- p["player_id"],
         token when is_binary(token) and token != "" <- p["token"],
         device when is_binary(device) and device != "" <- p["device_id"] do
      {:ok,
       %__MODULE__{
         player_id: id,
         token: token,
         device_id: device,
         handle: handle(p["handle"])
       }}
    else
      _ -> {:error, :invalid_player}
    end
  end

  def new(_), do: {:error, :invalid_player}

  defp handle(name) when is_binary(name) and name != "", do: String.slice(name, 0, 40)
  defp handle(_), do: "Player"

  def load(name) do
    path = Path.join("creds", name <> ".json")

    with {:ok, json} <- File.read(path),
         {:ok, map} <- Jason.decode(json) do
      {:ok,
       %__MODULE__{
         player_id: Map.fetch!(map, "player_id"),
         token: Map.fetch!(map, "token"),
         device_id: Map.get(map, "device_id", @default_device_id),
         handle: Map.get(map, "handle") || "Relay"
       }}
    else
      {:error, reason} -> {:error, "cannot read #{path}: #{inspect(reason)}"}
    end
  end
end

defimpl Inspect, for: TriviaRelay.Sporcle.Cred do
  def inspect(cred, _opts), do: "#TriviaRelay.Sporcle.Cred<#{cred.handle} #{cred.player_id}>"
end
