defmodule TriviaRelay.Sporcle.Cred do
  @moduledoc """
  One Sporcle account's Party credentials: the bare player id, the session token,
  a device id and the account's handle, and the name other players see in a game
  (`name`, the handle when the player hasn't chosen one).

  In the relay these arrive from the phone with each request (`new/1`) and are never
  kept. Each is checked for shape before it goes anywhere: they become headers on a
  Sporcle call and keys in the relay's meters, and the names are shown to other players.
  The spike console reads its own from files (`TriviaRelay.Spike.Creds`, dev only).
  """

  @enforce_keys [:player_id, :token, :device_id, :handle]
  defstruct @enforce_keys ++ [name: nil]

  @type t :: %__MODULE__{
          player_id: String.t(),
          token: String.t(),
          device_id: String.t(),
          handle: String.t(),
          name: String.t() | nil
        }

  @max_handle 40

  @doc """
  From a phone's request: `player_id`, `token`, `device_id`, `handle` and, optionally,
  `name`.
  """
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
         handle: handle(p["handle"]),
         name: name(p["name"])
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
  def handle(name), do: name |> clean() |> default_handle()

  @doc """
  The name the player chose to be seen by, cleaned as `handle/1` cleans a handle, or nil
  when they chose none (or nothing of it is left): then the handle is shown.
  """
  def name(name) do
    case clean(name) do
      "" -> nil
      name -> name
    end
  end

  @doc "The name other players see: the one chosen, else the handle."
  def display_name(%__MODULE__{name: name}) when is_binary(name), do: name
  def display_name(%__MODULE__{handle: handle}), do: handle

  defp clean(name), do: TriviaRelay.Text.clean(name, @max_handle)

  defp default_handle(""), do: "Player"
  defp default_handle(name), do: name
end

defimpl Inspect, for: TriviaRelay.Sporcle.Cred do
  def inspect(cred, _opts), do: "#TriviaRelay.Sporcle.Cred<#{cred.handle} #{cred.player_id}>"
end
