defmodule TriviaRelay.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TriviaRelayWeb.Telemetry,
      {Phoenix.PubSub, name: TriviaRelay.PubSub},
      TriviaRelay.RateLimit,
      TriviaRelay.Bypass,
      {Registry, keys: :unique, name: TriviaRelay.Seats.Registry},
      # One seat per Sporcle player (`TriviaRelay.Seats.Seat`).
      {Registry, keys: :unique, name: TriviaRelay.Seats.Players},
      {DynamicSupervisor,
       name: TriviaRelay.Seats.Supervisor,
       strategy: :one_for_one,
       max_children: TriviaRelay.Seats.max_seats()},
      TriviaRelayWeb.Endpoint,
      # Last, so it stops first: seats close out loud while the endpoint is still up.
      TriviaRelay.Seats.Drain
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TriviaRelay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TriviaRelayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
