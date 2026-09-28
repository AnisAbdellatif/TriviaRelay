defmodule TriviaRelayWeb.UserSocket do
  use Phoenix.Socket

  channel "seat:*", TriviaRelayWeb.SeatChannel

  # Anonymous: who somebody is, is the seat token they join a seat with
  # (protocol/PROTOCOL.md §3). The address is kept only to meter failed joins.
  @impl true
  def connect(_params, socket, connect_info) do
    {:ok, assign(socket, :ip, TriviaRelayWeb.ClientIp.from_connect_info(connect_info))}
  end

  @impl true
  def id(_socket), do: nil
end
