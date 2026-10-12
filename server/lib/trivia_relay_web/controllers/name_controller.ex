defmodule TriviaRelayWeb.NameController do
  @moduledoc """
  `POST /api/names/check` `{name}` (`protocol/PROTOCOL.md` §3.7, since 1.2): whether a
  name a player wants others to see is one Sporcle accepts, as the official app asks
  before saving a team name (`getHandleHasBadWords`). Credentials come from the
  `x-player-*` headers.

  Answers the name as the relay will pass it on (`TriviaRelay.Sporcle.Cred.name/1`) and
  whether Sporcle takes it. Nothing is kept: the app keeps the name, and sends it with
  each seat it takes.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Sporcle.{Api, Cred}
  alias TriviaRelayWeb.{ApiError, PackController, SporcleErrors}

  def check(conn, %{"name" => name}) when is_binary(name) do
    with {:ok, cred} <- Cred.new(PackController.player(conn)),
         clean when is_binary(clean) <- Cred.name(name),
         {:ok, bad?} <- Api.name_has_bad_words(cred, clean) do
      json(conn, %{name: clean, allowed: not bad?})
    else
      nil -> invalid(conn)
      error -> SporcleErrors.send_action(conn, error)
    end
  end

  def check(conn, _params), do: invalid(conn)

  defp invalid(conn),
    do: ApiError.send(conn, :bad_request, "invalid_request", "Type a name, up to 40 characters.")
end
