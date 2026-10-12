defmodule TriviaRelay.Spike.Creds do
  @moduledoc """
  The spike console's credentials, read from `creds/<name>.json`: the output of the
  scraper's `sporcle token <SLOT>`. Development only (`dev/`); the relay takes
  credentials from each request (`TriviaRelay.Sporcle.Cred.new/1`) and keeps none.
  """

  alias TriviaRelay.Sporcle.Cred

  # The scraper's default X-UDID, used when a credential file names none.
  @default_device_id "956aa24a2296d663"

  @spec load(String.t()) :: {:ok, Cred.t()} | {:error, String.t()}
  def load(name) do
    path = Path.join("creds", name <> ".json")

    with {:ok, json} <- File.read(path),
         {:ok, map} <- Jason.decode(json) do
      {:ok,
       %Cred{
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
