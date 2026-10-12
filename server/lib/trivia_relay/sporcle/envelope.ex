defmodule TriviaRelay.Sporcle.Envelope do
  @moduledoc """
  GameLift Realtime framing, as Sporcle Party's game server speaks it
  (`~/dev/sporcle_scraper/PROTOCOL.md` §7).

  A message on the socket is `varint(length) <> protobuf body`, and the game's own
  `["event", payload]` JSON rides in field 15 of the body:

    * game message: f1 opType (200), f3 target (-1), f5 8, f6 1, f7 2, f15 JSON
    * login:        no f1; f3 -1, f6 1, f7 2, f15 player JSON, f30 {f1 PlayerSessionId}

  The fields are GameLift Realtime's `Packet` (decompiled, `com.gamelift.rt.proto.Packet`
  in the official app's bundle): f1 opcode, f2 sequence number, f3 target player, f4
  target group, f5 sender, f6 reliable, f7 client version, f15 payload. A target of -1
  is `PLAYER_ID_SERVER` (0xFFFFFFFF as an int32): the game server, which passes the
  event on to everyone. A peer id as the target is the official app's `sendTo`, a
  message for that one player only (`game_to/4`). The f5 of 8 is what the captured
  official app sent as its sender; Sporcle ignores it on messages to the server.

  Server messages have the same shape, with f3 the receiving peer and f5 -1 (the
  server) (confirmed live). Only f15 is interpreted; `decode/1` keeps every field it
  finds, so a frame that is not a game message still reaches the log whole.
  """

  import Bitwise

  @op_game 200

  @doc "A game message carrying `[event, payload]` (or `[event]` with no payload)."
  def game(event, payload), do: game_json(Jason.encode!([event, payload]))
  def game(event), do: game_json(Jason.encode!([event]))

  @doc "A game message around JSON that is already encoded."
  def game_json(json) do
    frame([
      field(1, @op_game),
      field(3, -1),
      field(5, 8),
      field(6, 1),
      field(7, 2),
      bytes(15, json)
    ])
  end

  @doc """
  A game message for one player: `[event, payload]` to peer `target`, from peer `sender`
  (this connection's own), as the official app's `sendTo` sends a honk. The game server
  delivers it to that player alone.
  """
  def game_to(target, sender, event, payload)
      when is_integer(target) and target > 0 and is_integer(sender) do
    frame([
      field(1, @op_game),
      field(3, target),
      field(5, sender),
      field(6, 1),
      field(7, 2),
      bytes(15, Jason.encode!([event, payload]))
    ])
  end

  @doc "The first message on a connection: who the player is, and their PlayerSessionId."
  def login(player, session_id), do: login_json(Jason.encode!(player), session_id)

  def login_json(json, session_id) do
    frame([
      field(3, -1),
      field(6, 1),
      field(7, 2),
      bytes(15, json),
      bytes(30, bytes(1, session_id))
    ])
  end

  @doc """
  Splits a buffer into complete message bodies, returning `{bodies, rest}` where
  `rest` is an incomplete message still waiting for more bytes.

  A message whose length prefix says it is longer than `max` bytes is
  `{:error, :too_large}` at once, rather than something to wait for.
  """
  def split(data, max \\ :infinity), do: split(data, max, [])

  defp split(data, max, acc) do
    case read_varint(data) do
      {:ok, len, _rest} when is_integer(max) and len > max ->
        {:error, :too_large}

      {:ok, len, rest} when byte_size(rest) >= len ->
        <<body::binary-size(^len), more::binary>> = rest
        split(more, max, [body | acc])

      _ ->
        {Enum.reverse(acc), data}
    end
  end

  @doc """
  Decodes one message body into `%{fields: [...], event: ..., payload: ..., sender: ...}`.

  `fields` is every field in order as `{number, value}`: an integer for a varint
  (field 3 read as signed, since -1 means "everyone"), a binary for a
  length-delimited field. `event` and `payload` come from field 15 when it holds a
  JSON array, and are nil otherwise.

  `sender` is field 5 read signed: `-1` on a message from Sporcle's server (confirmed
  live), the sending peer's id (a positive integer) on a `sendTo` from another player,
  and `nil` when the field is absent. The seat uses it to tell a server message from a
  forged peer-to-peer one.
  """
  def decode(body) do
    case fields(body) do
      {:ok, fields} ->
        {event, payload} = game_event(List.keyfind(fields, 15, 0))
        {:ok, %{fields: fields, event: event, payload: payload, sender: sender(fields)}}

      :error ->
        :error
    end
  end

  defp sender(fields) do
    case List.keyfind(fields, 5, 0) do
      {5, value} when is_integer(value) -> signed(value)
      _ -> nil
    end
  end

  @doc "Decodes a protobuf body into `{:ok, [{number, value}]}`, or `:error`."
  def fields(body, acc \\ [])
  def fields(<<>>, acc), do: {:ok, Enum.reverse(acc)}

  def fields(body, acc) do
    with {:ok, tag, rest} <- read_varint(body),
         {:ok, value, rest} <- read_value(tag &&& 7, rest) do
      num = tag >>> 3
      fields(rest, [{num, if(num == 3, do: signed(value), else: value)} | acc])
    else
      _ -> :error
    end
  end

  defp read_value(0, data), do: read_varint(data)

  defp read_value(2, data) do
    with {:ok, len, rest} <- read_varint(data),
         <<value::binary-size(^len), rest::binary>> <- rest do
      {:ok, value, rest}
    else
      _ -> :error
    end
  end

  defp read_value(1, <<value::little-64, rest::binary>>), do: {:ok, {:fixed64, value}, rest}
  defp read_value(5, <<value::little-32, rest::binary>>), do: {:ok, {:fixed32, value}, rest}
  defp read_value(_, _), do: :error

  defp game_event({15, json}) do
    case Jason.decode(json) do
      {:ok, [event | rest]} when is_binary(event) -> {event, List.first(rest)}
      _ -> {nil, nil}
    end
  end

  defp game_event(nil), do: {nil, nil}

  defp signed(n) when is_integer(n) and n >= 1 <<< 63, do: n - (1 <<< 64)
  defp signed(n), do: n

  defp frame(fields) do
    body = IO.iodata_to_binary(fields)
    varint(byte_size(body)) <> body
  end

  defp field(num, value), do: [varint(num <<< 3), varint(value)]

  defp bytes(num, value) do
    value = IO.iodata_to_binary(value)
    [varint(num <<< 3 ||| 2), varint(byte_size(value)), value]
  end

  # Negative numbers go out as 64-bit two's complement, ten bytes on the wire.
  defp varint(n) when n < 0, do: varint(n &&& (1 <<< 64) - 1)
  defp varint(n) when n < 0x80, do: <<n>>
  defp varint(n), do: <<(n &&& 0x7F) ||| 0x80>> <> varint(n >>> 7)

  defp read_varint(data, shift \\ 0, acc \\ 0)

  defp read_varint(<<byte, rest::binary>>, shift, acc) when shift < 70 do
    acc = acc ||| (byte &&& 0x7F) <<< shift
    if byte >= 0x80, do: read_varint(rest, shift + 7, acc), else: {:ok, acc, rest}
  end

  defp read_varint(_, _, _), do: :error
end
