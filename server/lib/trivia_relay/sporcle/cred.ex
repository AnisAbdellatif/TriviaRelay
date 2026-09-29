defmodule TriviaRelay.Sporcle.Cred do
  @moduledoc """
  One Sporcle account's Party credentials: the bare player id, the session token,
  a device id and the handle other players see.

  In the relay these arrive from the phone with each request (`new/1`) and are never
  kept. Each is checked for shape before it goes anywhere: they become headers on a
  Sporcle call and keys in the relay's meters, and the handle is shown to other players.
  The spike console reads its own from files (`TriviaRelay.Spike.Creds`, dev only).
  """

  @enforce_keys [:player_id, :token, :device_id, :handle]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          player_id: String.t(),
          token: String.t(),
          device_id: String.t(),
          handle: String.t()
        }

  @max_handle 40

  @doc "From a phone's request: `player_id`, `token`, `device_id` and `handle`."
  def new(%{} = p) do
    with id when is_binary(id) <- p["player_id"],
         true <- player_id?(id),
         token when is_binary(token) <- p["token"],
         true <- token?(token),
         device when is_binary(device) <- p["device_id"],
         true <- device_id?(device) do
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

  # Sporcle's `user_id` (`xAc71a08as`) and its 64-hex token are only bounded, not
  # pinned: they are Sporcle's to change.
  defp player_id?(id), do: String.match?(id, ~r/\A[A-Za-z0-9_.-]{1,64}\z/)
  defp token?(token), do: String.match?(token, ~r/\A[\x21-\x7E]{1,256}\z/)

  @doc """
  Whether `id` is a device id as the app makes them: 16 lowercase hex, once per install
  (app/lib/core/storage/app_store.dart).
  """
  def device_id?(id), do: is_binary(id) and String.match?(id, ~r/\A[0-9a-f]{16}\z/)

  @doc """
  Who these credentials are, for keying what the relay keeps about an answer made with
  them (`TriviaRelay.Cache`): a hash of all three, so only the same credentials find it.
  """
  def key(%__MODULE__{} = cred),
    do: :crypto.hash(:sha256, [cred.player_id, 0, cred.token, 0, cred.device_id])

  @doc """
  The name other players see, as a person could have typed it: letters, marks and
  numbers of any script, punctuation, symbols (emoji), single spaces. What only moves
  or hides text is dropped — control characters, bidi overrides and isolates, zero-width
  characters — and so are marks stacked past a few. At most #{@max_handle} characters;
  "Player" when nothing is left.
  """
  def handle(name) when is_binary(name) do
    if String.valid?(name) do
      name
      |> String.replace(~r/[\x{09}-\x{0D}\x{85}\x{2028}\x{2029}]/u, " ")
      |> String.replace(~r/[^\p{L}\p{M}\p{N}\p{P}\p{S}\p{Zs}]/u, "")
      |> String.replace(~r/(\p{M}{3})\p{M}+/u, "\\1")
      |> String.replace(~r/\p{Zs}+/u, " ")
      |> String.trim()
      |> String.slice(0, @max_handle)
      |> String.trim()
      |> default_handle()
    else
      "Player"
    end
  end

  def handle(_), do: "Player"

  defp default_handle(""), do: "Player"
  defp default_handle(name), do: name
end

defimpl Inspect, for: TriviaRelay.Sporcle.Cred do
  def inspect(cred, _opts), do: "#TriviaRelay.Sporcle.Cred<#{cred.handle} #{cred.player_id}>"
end
