defmodule TriviaRelayWeb.WebsocketLimitsTest do
  @moduledoc """
  What a socket may be sent, through a real Bandit server with the endpoint's own
  settings (config.exs, endpoint.ex), by a client that speaks raw WebSocket frames.
  """

  use ExUnit.Case, async: true

  setup do
    websocket = Keyword.fetch!(TriviaRelayWeb.Endpoint.config(:http), :websocket_options)

    server =
      start_supervised!(
        {Bandit,
         plug: TriviaRelayWeb.Endpoint,
         ip: :loopback,
         port: 0,
         startup_log: false,
         websocket_options: websocket}
      )

    {:ok, {_ip, port}} = ThousandIsland.listener_info(server)
    {:ok, port: port}
  end

  test "a message in fragments is capped as a single frame is", %{port: port} do
    socket = open(port, false)
    :ok = :gen_tcp.send(socket, frame(0x1, String.duplicate("a", 10_000), fin: false))
    :ok = :gen_tcp.send(socket, frame(0x0, String.duplicate("a", 10_000)))
    assert closed_with(socket) == 1009
  end

  test "a compressed message may not inflate far", %{port: port} do
    socket = open(port, true)
    # A megabyte of JSON-ish nothing, deflated to a few KB.
    bomb =
      ~s([null,"1","phoenix","heartbeat",{"x":") <> String.duplicate("a", 1_000_000) <> ~s("}])

    :ok = :gen_tcp.send(socket, frame(0x1, deflate(bomb), compressed: true))
    assert closed_with(socket) == 1009
  end

  test "a real message, however well it compresses, goes through", %{port: port} do
    socket = open(port, true)

    padded =
      ~s([null,"1","phoenix","heartbeat",{"x":") <> String.duplicate("a", 15_000) <> ~s("}])

    :ok = :gen_tcp.send(socket, frame(0x1, deflate(padded), compressed: true))

    # The heartbeat's reply: a (compressed) text frame, not a close.
    assert {:ok, <<1::1, 1::1, 0::2, 0x1::4, _::bitstring>>} = :gen_tcp.recv(socket, 0, 2_000)
  end

  defp open(port, deflate?) do
    {:ok, socket} = :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false])

    extensions = if deflate?, do: "Sec-WebSocket-Extensions: permessage-deflate\r\n", else: ""

    :ok =
      :gen_tcp.send(socket, [
        "GET /socket/websocket?vsn=2.0.0 HTTP/1.1\r\n",
        "Host: localhost\r\n",
        "Upgrade: websocket\r\n",
        "Connection: Upgrade\r\n",
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n",
        "Sec-WebSocket-Version: 13\r\n",
        extensions,
        "\r\n"
      ])

    {:ok, response} = :gen_tcp.recv(socket, 0, 2_000)
    assert response =~ "HTTP/1.1 101"
    if deflate?, do: assert(response =~ "permessage-deflate")
    socket
  end

  defp closed_with(socket) do
    case :gen_tcp.recv(socket, 0, 2_000) do
      {:ok, <<1::1, 0::3, 0x8::4, 0::1, _len::7, code::16, _reason::binary>>} -> code
      other -> flunk("expected a close frame, got #{inspect(other)}")
    end
  end

  # A client's frame: masked, as RFC 6455 requires.
  defp frame(opcode, payload, opts \\ []) do
    fin = if Keyword.get(opts, :fin, true), do: 1, else: 0
    rsv1 = if Keyword.get(opts, :compressed, false), do: 1, else: 0
    mask = :crypto.strong_rand_bytes(4)

    length =
      case byte_size(payload) do
        n when n < 126 -> <<n::7>>
        n when n < 65_536 -> <<126::7, n::16>>
        n -> <<127::7, n::64>>
      end

    masks = :binary.copy(mask, div(byte_size(payload), 4) + 1)
    masked = :crypto.exor(payload, binary_part(masks, 0, byte_size(payload)))

    <<fin::1, rsv1::1, 0::2, opcode::4, 1::1, length::bitstring, mask::binary, masked::binary>>
  end

  # permessage-deflate: raw deflate, flushed, without the flush's trailing 00 00 FF FF.
  defp deflate(data) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    deflated = z |> :zlib.deflate(data, :sync) |> IO.iodata_to_binary()
    :zlib.close(z)
    binary_part(deflated, 0, byte_size(deflated) - 4)
  end
end
