defmodule TriviaRelay.Sporcle.Http do
  @moduledoc """
  Every request the relay makes to Sporcle goes through here, so tests can put a stub in
  front of all of them (`config :trivia_relay, :sporcle_http, plug: {Req.Test, …}`).
  Nothing is retried: creating or joining a game reserves a player session each time.
  """

  def request(opts) do
    [retry: false, receive_timeout: 25_000]
    |> Keyword.merge(opts)
    |> Keyword.merge(Application.get_env(:trivia_relay, :sporcle_http, []))
    |> Req.request()
  end
end
