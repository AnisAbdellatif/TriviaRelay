defmodule TriviaRelay.Bypass do
  @moduledoc """
  Admin-issued one-time codes that grant a host persistent bypass access to remove
  away players (`protocol/PROTOCOL.md §4.2 remove`).

  One-time codes are created by an admin at `/admin` and stored in a DETS file
  (disk-backed ETS, built into OTP; no external database needed). Each code may be
  redeemed once: the app POSTs `{code, device_id}` to `/api/bypass/redeem`, the relay
  marks the code used and returns an HMAC-signed bearer naming that code. The app
  stores the bearer and sends it with each bypass intent.

  A bearer is good only while its code is still in the table: deleting a redeemed
  code revokes the device that redeemed it.

  The DETS file persists across relay restarts but not across container replacements
  unless `BYPASS_DETS_PATH` points to a volume mount. Losing the file revokes every
  device.
  """

  use GenServer

  require Logger

  # Bearer tokens are good for one year.
  @bearer_ttl_ms :timer.hours(24 * 365)
  @table :trivia_relay_bypass

  ## Public API

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "True when `ADMIN_PASSWORD` is configured."
  def enabled?, do: Application.get_env(:trivia_relay, :admin_password) != nil

  @doc "Creates a random one-time code and stores it. Returns `{:ok, code}` or `:disabled`."
  def create_code do
    if enabled?() do
      code = Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
      :ok = GenServer.call(__MODULE__, {:put, code})
      {:ok, code}
    else
      :disabled
    end
  end

  @doc "Lists all codes: `[{code, used, created_at_ms}]`, newest first."
  def list_codes, do: GenServer.call(__MODULE__, :list)

  @doc "Deletes `code`, revoking the device that redeemed it, if any."
  def delete_code(code) when is_binary(code), do: GenServer.call(__MODULE__, {:delete, code})

  @doc """
  Redeems `code` for `device_id`.

  Returns `{:ok, bearer}` on success.
  Returns `{:error, :not_found | :already_used | :bypass_disabled}` otherwise.
  """
  def redeem(code, device_id) when is_binary(code) and is_binary(device_id) do
    if enabled?() do
      GenServer.call(__MODULE__, {:redeem, code, device_id})
    else
      {:error, :bypass_disabled}
    end
  end

  @doc """
  Verifies a bearer token: signed by this relay, not expired, and its code not
  deleted. Returns `{:ok, device_id}` or `:error`.
  """
  def verify_bearer(bearer) when is_binary(bearer) do
    with [code, device64, expires_str, mac] <- String.split(bearer, "."),
         {expires, ""} <- Integer.parse(expires_str),
         true <- System.system_time(:millisecond) < expires,
         true <- Plug.Crypto.secure_compare(sign("#{code}.#{device64}.#{expires}"), mac),
         true <- redeemed?(code),
         {:ok, device_id} <- Base.url_decode64(device64, padding: false) do
      {:ok, device_id}
    else
      _ -> :error
    end
  end

  def verify_bearer(_), do: :error

  ## GenServer

  @impl true
  def init(_opts) do
    path =
      Application.get_env(:trivia_relay, :bypass_dets_path) ||
        String.to_charlist(Path.join(System.tmp_dir!(), "trivia_relay_bypass.dets"))

    case :dets.open_file(@table, type: :set, file: path) do
      {:ok, @table} ->
        {:ok, @table}

      {:error, reason} ->
        Logger.error(
          "TriviaRelay.Bypass: could not open DETS at #{inspect(path)}: #{inspect(reason)}"
        )

        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:put, code}, _from, table) do
    :dets.insert(table, {code, false, System.system_time(:millisecond)})
    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:delete, code}, _from, table) do
    {:reply, :dets.delete(table, code), table}
  end

  @impl true
  def handle_call(:list, _from, table) do
    entries =
      :dets.foldl(
        fn {code, used, created_at}, acc -> [{code, used, created_at} | acc] end,
        [],
        table
      )

    sorted = Enum.sort_by(entries, fn {_, _, ts} -> -ts end)
    {:reply, sorted, table}
  end

  @impl true
  def handle_call({:redeem, code, device_id}, _from, table) do
    result =
      case :dets.lookup(table, code) do
        [{^code, false, created_at}] ->
          :dets.insert(table, {code, true, created_at})
          {:ok, issue_bearer(code, device_id)}

        [{^code, true, _}] ->
          {:error, :already_used}

        [] ->
          {:error, :not_found}
      end

    {:reply, result, table}
  end

  @impl true
  def terminate(_reason, table) do
    :dets.close(table)
  end

  ## Private

  # The device id is the app's, so it is encoded: it can't add a "." to the bearer.
  defp issue_bearer(code, device_id) do
    expires = System.system_time(:millisecond) + @bearer_ttl_ms
    data = "#{code}.#{Base.url_encode64(device_id, padding: false)}.#{expires}"
    "#{data}.#{sign(data)}"
  end

  defp sign(data) do
    secret = TriviaRelayWeb.Endpoint.config(:secret_key_base)
    :crypto.mac(:hmac, :sha256, secret, data) |> Base.encode16(case: :lower)
  end

  # Read straight from the table, from the caller: a DETS table serves any process.
  defp redeemed?(code) do
    match?([{^code, true, _}], :dets.lookup(@table, code))
  end
end
