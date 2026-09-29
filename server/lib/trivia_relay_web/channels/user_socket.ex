defmodule TriviaRelayWeb.UserSocket do
  use Phoenix.Socket

  alias TriviaRelay.RateLimit
  alias TriviaRelayWeb.ClientIp

  channel "seat:*", TriviaRelayWeb.SeatChannel

  # A socket costs memory for as long as it is open, whoever opened it, so each address
  # may open so many a minute and hold so many at once (an IPv6 caller per /64 and, with
  # four times the room, per /48). A household or a bar's wifi is one address with a
  # phone per player; these sit far above that. The endpoint caps every connection
  # together (`thousand_island_options`, runtime.exs).
  @connects_per_minute 60
  @open_per_address 40

  # Anonymous: who somebody is, is the seat token they join a seat with
  # (protocol/PROTOCOL.md §3). The address is kept only to meter failed joins.
  @impl true
  def connect(_params, socket, connect_info) do
    ip = ClientIp.from_connect_info(connect_info)

    if admitted?(ip), do: {:ok, assign(socket, :ip, ip)}, else: :error
  end

  @impl true
  def id(_socket), do: nil

  # Runs in the process that becomes the socket (Bandit upgrades in place), so a hold
  # taken here ends when the socket closes.
  defp admitted?(ip) do
    not TriviaRelayWeb.Plugs.RateLimit.enabled?() or
      (RateLimit.check_all(:socket_connects, ClientIp.limits(ip, @connects_per_minute), 60_000) ==
         :ok and hold_all(ClientIp.limits(ip, @open_per_address), []))
  end

  # Every key's place, or none of them.
  defp hold_all([], _held), do: true

  defp hold_all([{key, limit} | rest], held) do
    case RateLimit.hold(:open_sockets, key, limit) do
      :ok ->
        hold_all(rest, [key | held])

      {:error, :rate_limited} ->
        Enum.each(held, &RateLimit.release(:open_sockets, &1))
        false
    end
  end
end
