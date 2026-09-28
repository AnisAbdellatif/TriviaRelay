defmodule TriviaRelayWeb.Router do
  use TriviaRelayWeb, :router

  alias TriviaRelayWeb.Plugs.RateLimit

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Each of these makes calls to Sporcle for the caller, so each is metered per address.
  pipeline :login_limit do
    plug RateLimit, bucket: :login, limit: 10, window_ms: 60_000
  end

  pipeline :packs_limit do
    plug RateLimit, bucket: :packs, limit: 60, window_ms: 60_000
  end

  pipeline :seats_limit do
    plug RateLimit, bucket: :seats, limit: 20, window_ms: 60_000
  end

  scope "/", TriviaRelayWeb do
    get "/health", HealthController, :show
  end

  scope "/api", TriviaRelayWeb do
    pipe_through :api

    scope "/" do
      pipe_through :login_limit
      post "/login", LoginController, :create
    end

    scope "/" do
      pipe_through :packs_limit
      get "/packs", PackController, :index
    end

    scope "/" do
      pipe_through :seats_limit
      post "/seats", SeatController, :join
      post "/seats/host", SeatController, :host
      post "/seats/pack", SeatController, :change_pack
    end
  end
end
