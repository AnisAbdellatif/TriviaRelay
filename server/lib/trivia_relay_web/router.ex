defmodule TriviaRelayWeb.Router do
  use TriviaRelayWeb, :router

  alias TriviaRelayWeb.Plugs.{RateLimit, SameOrigin}

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Each of these makes calls to Sporcle for the caller, so each is metered per address
  # (an IPv6 caller per /64, and per /48 with four times the room). What a call led to is
  # metered in the controllers too (TriviaRelayWeb.Meters): failed logins per email and
  # across the relay, seats per Sporcle account, refused joins.

  # Only the web build the relay serves logs in here (the Android app logs in on the
  # phone), so only a page of the relay's own origin may.
  pipeline :login_limit do
    plug SameOrigin
    plug RateLimit, bucket: :login, limit: 10, window_ms: 60_000
  end

  pipeline :packs_limit do
    plug RateLimit, bucket: :packs, limit: 60, window_ms: 60_000
  end

  pipeline :games_limit do
    plug RateLimit, bucket: :games, limit: 30, window_ms: 60_000
  end

  pipeline :join_limit do
    plug RateLimit, bucket: :seat_joins, limit: 20, window_ms: 60_000
  end

  pipeline :host_limit do
    plug RateLimit, bucket: :seat_hosts, limit: 10, window_ms: 60_000
  end

  pipeline :pack_change_limit do
    plug RateLimit, bucket: :pack_changes, limit: 20, window_ms: 60_000
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
      pipe_through :games_limit
      get "/games", GameController, :index
    end

    scope "/" do
      pipe_through :join_limit
      post "/seats", SeatController, :join
    end

    scope "/" do
      pipe_through :host_limit
      post "/seats/host", SeatController, :host
    end

    scope "/" do
      pipe_through :pack_change_limit
      post "/seats/pack", SeatController, :change_pack
    end
  end
end
