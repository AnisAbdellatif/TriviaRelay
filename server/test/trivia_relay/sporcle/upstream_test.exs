defmodule TriviaRelay.Sporcle.UpstreamTest do
  use ExUnit.Case, async: true

  alias Mint.WebSocket.PerMessageDeflate
  alias TriviaRelay.Sporcle.Upstream
  alias TriviaRelay.Sporcle.Upstream.Deflate

  # A compressed binary frame as a server sends it: raw deflate, sync-flushed, with the
  # trailing 00 00 ff ff taken off (RFC 7692).
  defp compressed_frame(data) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    deflated = z |> :zlib.deflate(data, :sync) |> IO.iodata_to_binary()
    :zlib.close(z)
    size = byte_size(deflated) - 4
    <<body::binary-size(^size), 0, 0, 0xFF, 0xFF>> = deflated
    # Mint's frame record: {opcode, reserved (RSV1 set), mask, data, fin?}.
    {:binary, <<4::size(3)>>, nil, body, true}
  end

  defp inflater do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z, -15)
    %PerMessageDeflate{inflate: z, inflate_takeover?: true}
  end

  test "inflates a message of an ordinary size" do
    json = Jason.encode!(["game_info", %{"x" => String.duplicate("y", 10_000)}])

    assert {:ok, {:binary, <<0::size(3)>>, nil, ^json, true}, _} =
             Deflate.decode(compressed_frame(json), inflater())
  end

  test "refuses a message that would inflate past the limit" do
    bomb = compressed_frame(:binary.copy(<<0>>, Upstream.max_message_bytes() + 1))
    assert byte_size(elem(bomb, 3)) < 10_000
    assert {:error, {:too_large, :inflated}} = Deflate.decode(bomb, inflater())
  end

  test "garbage that doesn't inflate is an error, not a crash" do
    assert {:error, :bad_deflate} =
             Deflate.decode(
               {:binary, <<4::size(3)>>, nil, <<0xFF, 0xFF, 0xFF>>, true},
               inflater()
             )
  end

  test "status reports show no login, session or payload" do
    state = %{
      label: "seat1",
      session: %{"PlayerSessionId" => "psess-secret"},
      player: %{"deviceId" => "device-secret"},
      ws: nil,
      status: 101,
      buffer: <<>>,
      pending: 0
    }

    status =
      Upstream.format_status(%{
        state: state,
        message: {:"$gen_cast", {:send, "answer_question", %{guessText: "my-guess"}}},
        log: [{:in, "device-secret"}]
      })

    text = inspect(status, limit: :infinity, printable_limit: :infinity)
    for secret <- ~w(psess-secret device-secret my-guess), do: refute(text =~ secret)
    assert text =~ "seat1" and text =~ "answer_question"
  end

  test "a message for one player's status report names only the event" do
    status =
      Upstream.format_status(%{
        state: :whatever,
        message: {:"$gen_cast", {:send_to, 5, 2, "honk", %{peerId: 2, honk_type: "secret"}}}
      })

    assert status.message == {:"$gen_cast", {:send_to, "honk"}}
  end

  test "a message for one player before the socket is up is dropped, as any send" do
    assert {:noreply, %{ws: nil}} =
             Upstream.handle_cast({:send_to, 5, 2, "honk", %{}}, %{ws: nil})
  end
end
