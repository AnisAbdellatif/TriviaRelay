defmodule TriviaRelayWeb.ApiError do
  @moduledoc """
  The relay's HTTP error body, `{"code": ..., "message": ...}` (`protocol/PROTOCOL.md`
  §3). The code is what the app branches on; the message is for a person.
  """

  import Plug.Conn

  def send(conn, status, code, message) do
    conn
    |> put_status(status)
    |> Phoenix.Controller.json(%{code: code, message: message})
  end
end
