defmodule TriviaRelay.Sporcle.Upstream do
  @moduledoc """
  One player's connection to a GameLift game server: the socket the relay would
  hold open while the player's phone comes and goes.

  It connects to `wss://<DnsName>:<Port>/` with permessage-deflate, sends the
  login, answers WebSocket pings, records every frame in the `FrameLog`, and tells
  its owner what arrives:

    * `{:upstream, label, :connected}` once the login is sent
    * `{:upstream, label, {:event, name, payload, sender}}` for each game message
      (`sender` is `-1` from Sporcle's server, the sending peer from a `sendTo`, or `nil`)
    * `{:upstream, label, {:frame, fields}}` for a frame that is not a game message
    * `{:upstream, label, {:closed, reason}}` when the connection ends, just before
      this process stops

  `label` names the connection in the log and to the owner, since a rejoin opens
  another one.

  What arrives is bounded: a message (compressed on the wire, inflated, or reassembled
  from Sporcle's length-prefixed envelopes) larger than `max_message_bytes/0` closes the
  connection (`{:closed, {:too_large, _}}`), which the seat reports as `lost`. Sporcle's
  real messages are a few kilobytes. Crash reports and `:sys.get_status/1` show a
  summary, never the login (device id) or the PlayerSessionId.
  """

  use GenServer

  alias TriviaRelay.Sporcle.{Envelope, FrameLog, Identity}

  @max_message_bytes 1_048_576

  @doc "The largest message the connection takes, in bytes."
  def max_message_bytes, do: @max_message_bytes

  @doc """
  Options: `:owner`, `:label`, `:session` (the `playerSession` map from createGame or
  joinGame), `:player` (the login JSON, see `Identity.player/3`), and `:log`, a
  `FrameLog` for the spike console. The relay passes no log: a player's frames are
  theirs, and it keeps none of them.
  """
  def start_link(opts), do: GenServer.start_link(__MODULE__, Map.new(opts))

  @doc "Sends `[event, payload]` (`[event]` when payload is `:none`), and says how it went."
  def send_event(pid, event, payload \\ :none), do: GenServer.call(pid, {:send, event, payload})

  @doc """
  Sends `[event, payload]` without waiting: what the relay's seats use, so a stalled
  socket never holds a seat up. A send that fails ends the connection, as a failed pong
  would.
  """
  def cast_event(pid, event, payload \\ :none), do: GenServer.cast(pid, {:send, event, payload})

  @doc """
  Sends `[event, payload]` to one player only, peer `target`, from peer `sender` (this
  connection's own): the official app's `sendTo`, as a honk goes. Without waiting, like
  `cast_event/3`.
  """
  def cast_event_to(pid, target, sender, event, payload),
    do: GenServer.cast(pid, {:send_to, target, sender, event, payload})

  @doc "Cuts the TCP connection with no WebSocket close: what a phone losing signal looks like."
  def drop(pid), do: GenServer.cast(pid, :drop)

  @doc "Closes the WebSocket properly, with a close frame."
  def close(pid), do: GenServer.cast(pid, :close)

  @impl true
  def init(opts) do
    state =
      %{log: nil}
      |> Map.merge(opts)
      |> Map.merge(%{
        conn: nil,
        ref: nil,
        ws: nil,
        status: nil,
        headers: [],
        buffer: <<>>,
        # Bytes received towards a WebSocket message not yet complete.
        pending: 0
      })

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, s) do
    %{"DnsName" => host, "Port" => port, "PlayerSessionId" => session_id} = s.session
    ctl(s, "connecting", %{host: host, port: port, session_id: session_id})

    with {:ok, conn} <- Mint.HTTP.connect(:https, host, port, protocols: [:http1]),
         {:ok, conn, ref} <-
           Mint.WebSocket.upgrade(:wss, conn, "/", [{"user-agent", Identity.user_agent_ws()}],
             extensions: [__MODULE__.Deflate]
           ) do
      {:noreply, %{s | conn: conn, ref: ref}}
    else
      {:error, reason} -> finish(s, {:connect_failed, reason})
      {:error, _conn, reason} -> finish(s, {:upgrade_failed, reason})
    end
  end

  @impl true
  def handle_call({:send, _event, _payload}, _from, %{ws: nil} = s),
    do: {:reply, {:error, :not_connected}, s}

  def handle_call({:send, event, payload}, _from, s) do
    case send_game(s, event, payload) do
      {:ok, s} -> {:reply, :ok, s}
      {:error, s, reason} -> {:reply, {:error, reason}, s}
    end
  end

  @impl true
  def handle_cast({:send, _event, _payload}, %{ws: nil} = s), do: {:noreply, s}

  def handle_cast({:send_to, _target, _sender, _event, _payload}, %{ws: nil} = s),
    do: {:noreply, s}

  def handle_cast({:send_to, target, sender, event, payload}, s) do
    frame = Envelope.game_to(target, sender, event, payload)
    log_out(s, %{kind: "game", event: event, payload: payload, target: target}, frame)

    case send_frame(s, {:binary, frame}) do
      {:ok, s} -> {:noreply, s}
      {:error, s, reason} -> finish(s, {:send_failed, reason})
    end
  end

  def handle_cast({:send, event, payload}, s) do
    case send_game(s, event, payload) do
      {:ok, s} -> {:noreply, s}
      {:error, s, reason} -> finish(s, {:send_failed, reason})
    end
  end

  def handle_cast(:drop, s) do
    ctl(s, "drop", %{})
    if s.conn, do: Mint.HTTP.close(s.conn)
    finish(s, :dropped)
  end

  def handle_cast(:close, %{ws: nil} = s), do: handle_cast(:drop, s)

  def handle_cast(:close, s) do
    ctl(s, "close", %{})
    _ = send_frame(s, {:close, 1000, ""})
    Mint.HTTP.close(s.conn)
    finish(s, :closed_by_us)
  end

  @impl true
  def handle_info(message, %{conn: conn} = s) when conn != nil do
    case Mint.WebSocket.stream(conn, message) do
      {:ok, conn, responses} -> handle_responses(responses, %{s | conn: conn})
      {:error, _conn, reason, _} -> finish(s, {:socket, reason})
      :unknown -> {:noreply, s}
    end
  end

  def handle_info(_message, s), do: {:noreply, s}

  defp handle_responses([], s), do: {:noreply, s}

  defp handle_responses([response | rest], s) do
    case handle_response(response, s) do
      {:ok, s} -> handle_responses(rest, s)
      {:stop, reason, s} -> finish(s, reason)
    end
  end

  defp handle_response({:status, _ref, status}, s), do: {:ok, %{s | status: status}}
  defp handle_response({:headers, _ref, headers}, s), do: {:ok, %{s | headers: headers}}

  defp handle_response({:done, ref}, s) do
    case Mint.WebSocket.new(s.conn, ref, s.status, s.headers) do
      {:ok, conn, ws} ->
        ctl(s, "upgraded", %{status: s.status, headers: Map.new(s.headers)})
        login(%{s | conn: conn, ws: ws})

      {:error, conn, reason} ->
        {:stop, {:upgrade_rejected, s.status, reason}, %{s | conn: conn}}
    end
  end

  # Mint keeps an incomplete WebSocket message to itself, so what it holds is counted
  # here: the bytes received since a data message last came out whole.
  defp handle_response({:data, _ref, data}, s) do
    pending = s.pending + byte_size(data)

    case Mint.WebSocket.decode(s.ws, data) do
      {:ok, ws, frames} ->
        pending = if Enum.any?(frames, &data_frame?/1), do: 0, else: pending

        if pending > @max_message_bytes,
          do: {:stop, {:too_large, :websocket}, %{s | ws: ws}},
          else: handle_frames(frames, %{s | ws: ws, pending: pending})

      {:error, ws, reason} ->
        {:stop, {:bad_frame, reason}, %{s | ws: ws}}
    end
  end

  defp handle_response(_other, s), do: {:ok, s}

  defp login(s) do
    %{"PlayerSessionId" => session_id} = s.session
    frame = Envelope.login(s.player, session_id)
    log_out(s, %{kind: "login", payload: s.player, session_id: session_id}, frame)

    case send_frame(s, {:binary, frame}) do
      {:ok, s} ->
        notify(s, :connected)
        {:ok, s}

      {:error, s, reason} ->
        {:stop, {:login_failed, reason}, s}
    end
  end

  defp handle_frames([], s), do: {:ok, s}

  defp handle_frames([frame | rest], s) do
    case handle_frame(frame, s) do
      {:ok, s} -> handle_frames(rest, s)
      stop -> stop
    end
  end

  defp handle_frame({:binary, data}, s) do
    case Envelope.split(s.buffer <> data, @max_message_bytes) do
      {bodies, buffer} when byte_size(buffer) <= @max_message_bytes ->
        Enum.each(bodies, &inbound(s, &1))
        if buffer != <<>>, do: ctl(s, "partial", %{bytes: byte_size(buffer)})
        {:ok, %{s | buffer: buffer}}

      _too_large ->
        {:stop, {:too_large, :envelope}, %{s | buffer: <<>>}}
    end
  end

  defp handle_frame({:text, text}, s) do
    FrameLog.write(s.log, s.label, "in", %{kind: "text", text: text})
    notify(s, {:frame, [{:text, text}]})
    {:ok, s}
  end

  defp handle_frame({:ping, data}, s) do
    if s.log, do: ctl(s, "ping", %{hex: Base.encode16(data, case: :lower)})

    case send_frame(s, {:pong, data}) do
      {:ok, s} -> {:ok, s}
      {:error, s, reason} -> {:stop, {:pong_failed, reason}, s}
    end
  end

  defp handle_frame({:pong, data}, s) do
    if s.log, do: ctl(s, "pong", %{hex: Base.encode16(data, case: :lower)})
    {:ok, s}
  end

  defp handle_frame({:close, code, reason}, s), do: {:stop, {:server_closed, code, reason}, s}
  defp handle_frame({:error, reason}, s), do: {:stop, {:bad_frame, reason}, s}

  # The relay keeps no log: the hex and the envelope fields are only worked out for one.
  defp inbound(%{log: nil} = s, body) do
    case Envelope.decode(body) do
      {:ok, %{event: nil, fields: fields}} ->
        notify(s, {:frame, fields})

      {:ok, %{event: event, payload: payload, sender: sender}} ->
        notify(s, {:event, event, payload, sender})

      :error ->
        :ok
    end
  end

  defp inbound(s, body) do
    hex = Base.encode16(body, case: :lower)

    case Envelope.decode(body) do
      {:ok, %{event: nil, fields: fields}} ->
        FrameLog.write(s.log, s.label, "in", %{
          kind: "frame",
          fields: FrameLog.fields(fields),
          hex: hex
        })

        notify(s, {:frame, fields})

      {:ok, %{event: event, payload: payload, fields: fields, sender: sender}} ->
        FrameLog.write(s.log, s.label, "in", %{
          kind: "game",
          event: event,
          payload: payload,
          fields: FrameLog.fields(List.keydelete(fields, 15, 0)),
          hex: hex
        })

        notify(s, {:event, event, payload, sender})

      :error ->
        FrameLog.write(s.log, s.label, "in", %{kind: "undecodable", hex: hex})
    end
  end

  defp send_game(s, event, payload) do
    frame = if payload == :none, do: Envelope.game(event), else: Envelope.game(event, payload)
    log_out(s, %{kind: "game", event: event, payload: nilify(payload)}, frame)
    send_frame(s, {:binary, frame})
  end

  defp data_frame?({kind, _data}), do: kind in [:binary, :text]
  defp data_frame?(_frame), do: false

  defp send_frame(s, frame) do
    with {:ok, ws, data} <- Mint.WebSocket.encode(s.ws, frame),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(s.conn, s.ref, data) do
      {:ok, %{s | ws: ws, conn: conn}}
    else
      {:error, _, reason} -> {:error, s, reason}
    end
  end

  defp finish(s, reason) do
    ctl(s, "closed", %{reason: inspect(reason)})
    notify(s, {:closed, reason})
    {:stop, :normal, s}
  end

  defp log_out(%{log: nil}, _entry, _frame), do: :ok

  defp log_out(s, entry, frame) do
    FrameLog.write(
      s.log,
      s.label,
      "out",
      Map.put(entry, :hex, Base.encode16(frame, case: :lower))
    )
  end

  defp ctl(s, what, details),
    do: FrameLog.write(s.log, s.label, "ctl", Map.put(details, :kind, what))

  defp notify(s, message), do: send(s.owner, {:upstream, s.label, message})

  defp nilify(:none), do: nil
  defp nilify(payload), do: payload

  # The login carries the device id and the session its PlayerSessionId, and frames carry
  # other players' names and answers: none of them belong in a crash report.
  @impl true
  def format_status(status) do
    Map.new(status, fn
      {:state, %{label: _} = s} ->
        {:state,
         %{
           label: s.label,
           upgraded: s.ws != nil,
           status: s.status,
           buffered: byte_size(s.buffer),
           pending: s.pending
         }}

      {:state, _} ->
        {:state, :redacted}

      {:message, message} ->
        {:message, tag(message)}

      {:queue, queue} when is_list(queue) ->
        {:queue, Enum.map(queue, &tag/1)}

      {:log, _} ->
        {:log, []}

      {:reason, reason} ->
        {:reason, reason(reason)}

      other ->
        other
    end)
  end

  defp tag({:"$gen_call", _from, request}), do: {:"$gen_call", tag(request)}
  defp tag({:"$gen_cast", request}), do: {:"$gen_cast", tag(request)}
  defp tag({:send, event, _payload}), do: {:send, event}
  defp tag({:send_to, _target, _sender, event, _payload}), do: {:send_to, event}
  defp tag(message) when is_tuple(message) and tuple_size(message) > 0, do: elem(message, 0)
  defp tag(message) when is_atom(message), do: message
  defp tag(_message), do: :redacted

  defp reason({%{__exception__: true} = error, stack}) when is_list(stack),
    do: {error.__struct__, Enum.map(stack, &frame/1)}

  defp reason({kind, stack}) when is_atom(kind) and is_list(stack),
    do: {kind, Enum.map(stack, &frame/1)}

  defp reason(reason) when is_atom(reason), do: reason
  defp reason(reason), do: tag(reason)

  defp frame({m, f, args, location}) when is_list(args), do: {m, f, length(args), location}
  defp frame(frame), do: frame
end

defmodule TriviaRelay.Sporcle.Upstream.Deflate do
  @moduledoc false
  # permessage-deflate as `Mint.WebSocket.PerMessageDeflate` does it, except that a
  # message inflating past `Upstream.max_message_bytes/0` is an error rather than all of
  # memory: a few kilobytes of compressed JSON can say gigabytes.

  @behaviour Mint.WebSocket.Extension

  require Mint.WebSocket.Frame, as: Frame

  alias Mint.WebSocket.PerMessageDeflate
  alias TriviaRelay.Sporcle.Upstream

  @impl true
  def name, do: PerMessageDeflate.name()

  @impl true
  def init(extension, extensions), do: PerMessageDeflate.init(extension, extensions)

  @impl true
  def encode(frame, state), do: PerMessageDeflate.encode(frame, state)

  @impl true
  def decode(frame, state)

  for opcode <- [:text, :binary, :continuation] do
    def decode(
          Frame.unquote(opcode)(reserved: <<1::size(1), _::bitstring>> = bits, data: data) =
            frame,
          state
        ) do
      <<reserved::size(3)>> = bits

      with {:ok, data} <- inflate(state.inflate, <<data::binary, 0x00, 0x00, 0xFF, 0xFF>>) do
        if state.inflate_takeover? == false, do: :zlib.inflateReset(state.inflate)

        frame =
          Frame.unquote(opcode)(frame,
            reserved: <<:erlang.bxor(reserved, 0b100)::size(3)>>,
            data: data
          )

        {:ok, frame, state}
      end
    end
  end

  def decode(frame, state), do: {:ok, frame, state}

  defp inflate(z, data) do
    collect(z, :zlib.safeInflate(z, data), [], 0)
  rescue
    ErlangError -> {:error, :bad_deflate}
  end

  defp collect(z, {status, out}, acc, size) when status in [:continue, :finished] do
    size = size + IO.iodata_length(out)

    cond do
      size > Upstream.max_message_bytes() -> {:error, {:too_large, :inflated}}
      status == :finished -> {:ok, IO.iodata_to_binary([acc, out])}
      true -> collect(z, :zlib.safeInflate(z, []), [acc, out], size)
    end
  end

  defp collect(_z, _other, _acc, _size), do: {:error, :bad_deflate}
end
