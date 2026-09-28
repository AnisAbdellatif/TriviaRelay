defmodule TriviaRelayWeb.HealthController do
  use TriviaRelayWeb, :controller

  def show(conn, _params), do: json(conn, %{status: "ok"})
end
