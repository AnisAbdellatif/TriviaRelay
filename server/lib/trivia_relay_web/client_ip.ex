defmodule TriviaRelayWeb.ClientIp do
  @moduledoc """
  Which address a request or a socket came from.

  Behind our proxies the peer is always the nearest of them, so the address comes from
  `X-Forwarded-For`, where each proxy appends the peer it saw. In production there are
  two — the host's Caddy writes the visitor, then kamal-proxy appends Caddy — so the
  visitor is the second entry from the right, and anything
  before it is whatever the client chose to send. `:proxy_hops` (`TRUST_PROXY`) is how
  many of those entries are ours. That is only believable because nothing but our
  proxies can reach the app; with no hops trusted, the peer is the answer.

  Used by the rate limiter and by the seat socket, so the two can never disagree about
  who somebody is. Copied from FazouraParty's `FazouraWeb.ClientIp`.

  An IPv6 address answers as its /64 network (`2001:db8:1:2::/64`). One subscriber is
  normally handed a whole /64 and can use any address in it, so counting single
  addresses would give anybody with IPv6 a fresh identity per request — past every rate
  limit and every ban. A /48 is cheap too (free tunnel brokers hand them out, 65,536
  /64s each), so meters also count the /48 it sits in (`limits/2`), with more room,
  since one /48 can be many unrelated subscribers.
  """

  # How much more a /48 may do than one /64 in it.
  @wide_factor 4

  @spec from_conn(Plug.Conn.t()) :: String.t()
  def from_conn(conn) do
    forwarded = conn |> Plug.Conn.get_req_header("x-forwarded-for") |> forwarded_client()
    normalize(forwarded || conn.remote_ip)
  end

  @doc "From a socket's `connect_info` (`:peer_data` and `:x_headers`), or nil without it."
  @spec from_connect_info(map()) :: String.t() | nil
  def from_connect_info(connect_info) do
    forwarded =
      for({"x-forwarded-for", value} <- Map.get(connect_info, :x_headers, []), do: value)
      |> forwarded_client()

    peer =
      case connect_info do
        %{peer_data: %{address: address}} -> address
        _ -> nil
      end

    normalize(forwarded || peer)
  end

  @doc """
  Every key a caller is metered under, each with its limit when one address may make
  `limit` requests: the address itself, and for IPv6 also its /48, allowed
  `#{@wide_factor}` times as many. Nil (no address known) is metered as `"unknown"`.
  """
  @spec limits(String.t() | nil, pos_integer()) :: [{String.t(), pos_integer()}]
  def limits(nil, limit), do: [{"unknown", limit}]

  def limits(address, limit) do
    case wide(address) do
      nil -> [{address, limit}]
      wide -> [{address, limit}, {wide, limit * @wide_factor}]
    end
  end

  # The /48 an IPv6 /64 (as `normalize/1` writes it) belongs to.
  defp wide(address) do
    with [network, "64"] <- String.split(address, "/"),
         {:ok, {a, b, c, _, _, _, _, _}} <- :inet.parse_address(String.to_charlist(network)) do
      ntoa({a, b, c, 0, 0, 0, 0, 0}) <> "/48"
    else
      _ -> nil
    end
  end

  # The entry the outermost of our proxies appended: `hops` from the right. Fewer
  # entries than that means the request skipped the outer ones (it was sent from the
  # server itself), and every entry is still one of ours: the first is the furthest
  # peer any of them saw.
  defp forwarded_client(values) do
    case Application.get_env(:trivia_relay, :proxy_hops) || 0 do
      0 ->
        nil

      hops ->
        entries =
          values
          |> Enum.flat_map(&String.split(&1, ","))
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        Enum.at(entries, -hops) || List.first(entries)
    end
  end

  defp normalize(nil), do: nil

  defp normalize(address) when is_binary(address) do
    case :inet.parse_address(String.to_charlist(address)) do
      {:ok, parsed} -> normalize(parsed)
      # Not an address: whatever the proxy wrote, as it wrote it.
      {:error, _reason} -> address
    end
  end

  # IPv4 mapped into IPv6 is the IPv4 address.
  defp normalize({0, 0, 0, 0, 0, 0xFFFF, high, low}),
    do: normalize({div(high, 256), rem(high, 256), div(low, 256), rem(low, 256)})

  defp normalize({a, b, c, d, _, _, _, _}),
    do: ntoa({a, b, c, d, 0, 0, 0, 0}) <> "/64"

  defp normalize(address), do: ntoa(address)

  defp ntoa(address), do: address |> :inet.ntoa() |> to_string()
end
