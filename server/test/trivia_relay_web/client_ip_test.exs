defmodule TriviaRelayWeb.ClientIpTest do
  use ExUnit.Case, async: true

  alias TriviaRelayWeb.ClientIp

  test "an IPv4 caller is metered under its address alone" do
    assert ClientIp.limits("203.0.113.7", 10) == [{"203.0.113.7", 10}]
  end

  test "an IPv6 caller is metered under its /64 and, with more room, its /48" do
    ip = ClientIp.from_connect_info(%{peer_data: %{address: {0x2001, 0xDB8, 1, 2, 3, 4, 5, 6}}})
    assert ip == "2001:db8:1:2::/64"
    assert ClientIp.limits(ip, 10) == [{"2001:db8:1:2::/64", 10}, {"2001:db8:1::/48", 40}]
  end

  test "every /64 of one /48 shares the /48's meter" do
    [_, {wide_a, _}] = ClientIp.limits("2001:db8:1:2::/64", 1)
    [_, {wide_b, _}] = ClientIp.limits("2001:db8:1:ffff::/64", 1)
    assert wide_a == wide_b
  end

  test "an unknown address is one caller" do
    assert ClientIp.limits(nil, 5) == [{"unknown", 5}]
  end
end
