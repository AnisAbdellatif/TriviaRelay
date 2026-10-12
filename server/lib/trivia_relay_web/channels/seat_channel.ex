defmodule TriviaRelayWeb.SeatChannel do
  @moduledoc """
  A phone's connection to its seat (`protocol/PROTOCOL.md` §4–5): `seat:<id>`, joined
  with the seat token the seat was created with, again on every reconnect.

  A transport adapter only: it checks the token, attaches to the seat, passes intents
  through and pushes what the seat sends. Snapshots arrive as `state`, the end as
  `seat_closed`. After each snapshot the channel hibernates, which returns the garbage
  encoding it left behind (FazouraParty measured this; see its decisions.md).

  Intents are metered per socket and per seat, so neither another socket nor another
  phone on the same seat adds to what a seat can send Sporcle. What goes on to other
  players (chat messages, typing, reactions) is metered again per seat, more tightly: each
  is a message from the relay's address that other people see or hear.
  """

  # Join parameters are seat tokens: never logged.
  use Phoenix.Channel, log_join: false, log_handle_in: false

  alias TriviaRelay.{Protocol, RateLimit, Seats}
  alias TriviaRelay.Seats.Seat
  alias TriviaRelayWeb.ClientIp

  # Failed joins are how somebody would test seat tokens; working ones are never counted,
  # so a phone reconnecting after a blip is untouched.
  @failed_join_limit 30
  @failed_join_window_ms 60_000
  # Per socket, and again per seat across all its phones.
  @event_limit 60
  @event_window_ms 10_000
  # Per seat, for what reaches other players: `{bucket, limit, window_ms}`.
  @social_limits %{
    "chat_send" => {:seat_chat, 5, 10_000},
    "chat_typing" => {:seat_typing, 10, 10_000},
    "chat_more" => {:seat_chat_more, 10, 60_000},
    "honk" => {:seat_reactions, 15, 60_000},
    "react" => {:seat_reactions, 15, 60_000}
  }

  @messages %{
    "version_mismatch" => "This app is too old or too new for this server. Update the app.",
    "invalid_token" => "This seat's token is not valid.",
    "seat_not_found" => "This seat has ended.",
    "rate_limited" => "Too many attempts. Wait a moment and try again.",
    "not_live" => "Not connected to the game yet.",
    "not_host" => "Only the host can do that.",
    "wrong_phase" => "That can't be done right now.",
    "already_answered" => "You already answered.",
    "already_voted" => "You already voted.",
    "already_wagered" => "You already wagered.",
    "not_everyone_answered" => "Not everyone has answered yet.",
    "invalid_wager" => "That wager isn't available.",
    "invalid_options" => "Those game options aren't allowed.",
    "invalid_intent" => "Unknown request.",
    "spectating" => "You're hosting as a spectator.",
    "too_many_votes" => "You can vote for up to 5 packs a game.",
    "draft_pack" => "That pack is a draft. Make it live first.",
    "bypass_revoked" => "Bypass access was revoked."
  }

  @impl true
  def join("seat:" <> id, params, socket) do
    ip = socket.assigns[:ip] || "unknown"

    with :ok <- joins_left(ip),
         :ok <- version(params["protocol_version"]),
         {:ok, pid} <- seat(id, params["seat_token"], ip),
         :ok <- Seat.attach(pid, self()) do
      Process.monitor(pid)
      {:ok, socket |> assign(:seat, pid) |> assign(:seat_id, id)}
    else
      {:error, code} -> {:error, error(code)}
    end
  end

  @impl true
  def handle_in(event, payload, socket) do
    with :ok <- metered(socket),
         :ok <- social(socket, event),
         :ok <- intent(socket.assigns.seat, event, payload) do
      {:reply, :ok, socket}
    else
      {:error, code} -> {:reply, {:error, error(code)}, socket}
    end
  end

  @impl true
  def handle_info({:seat_state, view}, socket) do
    push(socket, "state", view)
    {:noreply, socket, :hibernate}
  end

  def handle_info({:seat_closed, closed}, socket) do
    push(socket, "seat_closed", closed)
    {:stop, :normal, socket}
  end

  # More phones attached to the seat than it takes, and this was the oldest. Closed
  # without a word, so the phone does not rejoin and push the newer one out in turn.
  def handle_info(:seat_detached, socket), do: {:stop, :normal, socket}

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{assigns: %{seat: pid}} = socket) do
    push(socket, "seat_closed", %{reason: "shutdown"})
    {:stop, :normal, socket}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp seat(id, token, ip) do
    result =
      with {:ok, ^id} <- Seats.verify(token),
           pid when is_pid(pid) <- Seats.whereis(id) do
        {:ok, pid}
      else
        {:ok, _other} -> {:error, "invalid_token"}
        {:error, _} -> {:error, "invalid_token"}
        nil -> {:error, "seat_not_found"}
      end

    with {:error, _} <- result do
      RateLimit.check_all(
        :failed_joins,
        ClientIp.limits(ip, @failed_join_limit),
        @failed_join_window_ms
      )
    end

    result
  end

  defp joins_left(ip) do
    if RateLimit.any_exceeded?(
         :failed_joins,
         ClientIp.limits(ip, @failed_join_limit),
         @failed_join_window_ms
       ),
       do: {:error, "rate_limited"},
       else: :ok
  end

  defp version(major) do
    if major == Protocol.major(), do: :ok, else: {:error, "version_mismatch"}
  end

  defp metered(socket) do
    with :ok <- meter(:seat_events, inspect(socket.transport_pid)),
         do: meter(:seat_intents, socket.assigns.seat_id)
  end

  defp social(socket, event) do
    case @social_limits[event] do
      nil -> :ok
      {bucket, limit, window_ms} -> meter(bucket, socket.assigns.seat_id, limit, window_ms)
    end
  end

  defp meter(bucket, key, limit \\ @event_limit, window_ms \\ @event_window_ms) do
    case RateLimit.check(bucket, key, limit, window_ms) do
      :ok -> :ok
      {:error, :rate_limited} -> {:error, "rate_limited"}
    end
  end

  defp intent(pid, event, payload) do
    Seat.intent(pid, event, payload)
  catch
    :exit, _ -> {:error, "seat_not_found"}
  end

  defp error(code), do: %{code: code, message: message(code)}

  @doc "The words for an error `code`, for a person."
  def message(code), do: Map.get(@messages, code, "Something went wrong.")
end
