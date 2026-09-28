defmodule TriviaRelay.Sporcle.Upstream do
  @moduledoc """
  One player's connection to a GameLift game server: the socket the relay would
  hold open while the player's phone comes and goes.

  It connects to `wss://<DnsName>:<Port>/` with permessage-deflate, sends the
  login, answers WebSocket pings, records every frame in the `FrameLog`, and tells
  its owner what arrives:

    * `{:upstream, label, :connected}` once the login is sent
    * `{:upstream, label, {:event, name, payload}}` for each game message
    * `{:upstream, label, {:frame, fields}}` for a frame that is not a game message
    * `{:upstream, label, {:closed, reason}}` when the connection ends, just before
      this process stops

  `label` names the connection in the log and to the owner, since a rejoin opens
  another one.
  """

  use GenServer

  alias TriviaRelay.Sporcle.{Envelope, FrameLog, Identity}

  @doc """
  Options: `:owner`, `:label`, `:session` (the `playerSession` map from createGame or
  joinGame), `:player` (the login JSON, see `Identity.player/3`), and `:log`, a
  `FrameLog` for the spike console. The relay passes no log: a player's frames are
  theirs, and it keeps none of them.
  """
  def start_link(opts), do: GenServer.start_link(__MODULE__, Map.new(opts))

  @doc "Sends `[event, payload]` (`[event]` when payload is `:none`)."
  def send_event(pid, event, payload \\ :none), do: GenServer.call(pid, {:send, event, payload})

  @doc "Cuts the TCP connection with no WebSocket close: what a phone losing signal looks like."
  def drop(pid), do: GenServer.cast(pid, :drop)

  @doc "Closes the WebSocket properly, with a close frame."
  def close(pid), do: GenServer.cast(pid, :close)

  @impl true
  def init(opts) do
    state =
      %{log: nil}
      |> Map.merge(opts)
      |> Map.merge(%{conn: nil, ref: nil, ws: nil, status: nil, headers: [], buffer: <<>>})

    {:ok, state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, s) do
    %{"DnsName" => host, "Port" => port, "PlayerSessionId" => session_id} = s.session
    ctl(s, "connecting", %{host: host, port: port, session_id: session_id})

    with {:ok, conn} <- Mint.HTTP.connect(:https, host, port, protocols: [:http1]),
         {:ok, conn, ref} <-
           Mint.WebSocket.upgrade(:wss, conn, "/", [{"user-agent", Identity.user_agent_ws()}],
             extensions: [Mint.WebSocket.PerMessageDeflate]
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
    frame = if payload == :none, do: Envelope.game(event), else: Envelope.game(event, payload)
    log_out(s, %{kind: "game", event: event, payload: nilify(payload)}, frame)

    case send_frame(s, {:binary, frame}) do
      {:ok, s} -> {:reply, :ok, s}
      {:error, s, reason} -> {:reply, {:error, reason}, s}
    end
  end

  @impl true
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

  defp handle_response({:data, _ref, data}, s) do
    case Mint.WebSocket.decode(s.ws, data) do
      {:ok, ws, frames} -> handle_frames(frames, %{s | ws: ws})
      {:error, ws, reason} -> {:stop, {:bad_frame, reason}, %{s | ws: ws}}
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
    {bodies, buffer} = Envelope.split(s.buffer <> data)
    Enum.each(bodies, &inbound(s, &1))
    if buffer != <<>>, do: ctl(s, "partial", %{bytes: byte_size(buffer)})
    {:ok, %{s | buffer: buffer}}
  end

  defp handle_frame({:text, text}, s) do
    FrameLog.write(s.log, s.label, "in", %{kind: "text", text: text})
    notify(s, {:frame, [{:text, text}]})
    {:ok, s}
  end

  defp handle_frame({:ping, data}, s) do
    ctl(s, "ping", %{hex: Base.encode16(data, case: :lower)})

    case send_frame(s, {:pong, data}) do
      {:ok, s} -> {:ok, s}
      {:error, s, reason} -> {:stop, {:pong_failed, reason}, s}
    end
  end

  defp handle_frame({:pong, data}, s) do
    ctl(s, "pong", %{hex: Base.encode16(data, case: :lower)})
    {:ok, s}
  end

  defp handle_frame({:close, code, reason}, s), do: {:stop, {:server_closed, code, reason}, s}
  defp handle_frame({:error, reason}, s), do: {:stop, {:bad_frame, reason}, s}

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

      {:ok, %{event: event, payload: payload, fields: fields}} ->
        FrameLog.write(s.log, s.label, "in", %{
          kind: "game",
          event: event,
          payload: payload,
          fields: FrameLog.fields(List.keydelete(fields, 15, 0)),
          hex: hex
        })

        notify(s, {:event, event, payload})

      :error ->
        FrameLog.write(s.log, s.label, "in", %{kind: "undecodable", hex: hex})
    end
  end

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
end
