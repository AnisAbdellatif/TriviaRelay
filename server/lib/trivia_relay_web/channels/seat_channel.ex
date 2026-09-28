defmodule TriviaRelayWeb.SeatChannel do
  @moduledoc """
  A phone's connection to its seat (`protocol/PROTOCOL.md` §4–5): `seat:<id>`, joined
  with the seat token the seat was created with, again on every reconnect.

  A transport adapter only: it checks the token, attaches to the seat, passes intents
  through and pushes what the seat sends. Snapshots arrive as `state`, the end as
  `seat_closed`. After each snapshot the channel hibernates, which returns the garbage
  encoding it left behind (FazouraParty measured this; see its decisions.md).
  """

  # Join parameters are seat tokens: never logged.
  use Phoenix.Channel, log_join: false, log_handle_in: false

  alias TriviaRelay.{Protocol, RateLimit, Seats}
  alias TriviaRelay.Seats.Seat

  # Failed joins are how somebody would test seat tokens; working ones are never counted,
  # so a phone reconnecting after a blip is untouched.
  @failed_join_limit 30
  @failed_join_window_ms 60_000
  @event_limit 60
  @event_window_ms 10_000

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
    "invalid_intent" => "Unknown request."
  }

  @impl true
  def join("seat:" <> id, params, socket) do
    ip = socket.assigns[:ip] || "unknown"

    with :ok <- joins_left(ip),
         :ok <- version(params["protocol_version"]),
         {:ok, pid} <- seat(id, params["seat_token"], ip),
         :ok <- Seat.attach(pid, self()) do
      Process.monitor(pid)
      {:ok, assign(socket, :seat, pid)}
    else
      {:error, code} -> {:error, error(code)}
    end
  end

  @impl true
  def handle_in(event, payload, socket) do
    with :ok <- metered(socket),
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

  def handle_info({:seat_closed, reason}, socket) do
    push(socket, "seat_closed", %{reason: reason})
    {:stop, :normal, socket}
  end

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
      RateLimit.check(:failed_joins, ip, @failed_join_limit, @failed_join_window_ms)
    end

    result
  end

  defp joins_left(ip) do
    if RateLimit.exceeded?(:failed_joins, ip, @failed_join_limit, @failed_join_window_ms),
      do: {:error, "rate_limited"},
      else: :ok
  end

  defp version(major) do
    if major == Protocol.major(), do: :ok, else: {:error, "version_mismatch"}
  end

  defp metered(socket) do
    case RateLimit.check(
           :seat_events,
           inspect(socket.transport_pid),
           @event_limit,
           @event_window_ms
         ) do
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
