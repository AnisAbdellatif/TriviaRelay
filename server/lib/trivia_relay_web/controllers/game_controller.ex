defmodule TriviaRelayWeb.GameController do
  @moduledoc """
  `GET /api/games` (`protocol/PROTOCOL.md` §3.4): the games a player could join, as the
  official app's join screen lists them, made with the caller's credentials from headers.
  Joining one is `POST /api/seats` with its code.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Cache
  alias TriviaRelay.Sporcle.{Api, Cred}
  alias TriviaRelayWeb.{PackController, SporcleErrors}

  # The games screen asks every 15 s per phone; Sporcle's answer is kept this long for
  # the same credentials (TriviaRelay.Cache), never shared with anybody else's.
  @ttl_ms 10_000

  def index(conn, _params) do
    with {:ok, cred} <- Cred.new(PackController.player(conn)),
         {:ok, games} <- Cache.fetch({:games, Cred.key(cred)}, @ttl_ms, fn -> fetch(cred) end) do
      json(conn, %{games: games})
    else
      error -> SporcleErrors.send(conn, error)
    end
  end

  defp fetch(cred) do
    with {:ok, lists} <- Api.joinable_games(cred), do: {:ok, games(lists)}
  end

  # Invited, then friends, then public; within each, lobbies first, then the fullest games
  # first. A game in more than one list shows once, in the first.
  defp games(lists) do
    lists
    |> Enum.flat_map(fn {list, games} ->
      games
      |> Enum.flat_map(&game(&1, list))
      |> Enum.sort_by(&{&1.stage != "lobby", -players(&1)})
    end)
    |> Enum.uniq_by(& &1.code)
  end

  defp game(%{"gameCode" => code} = g, list) when is_binary(code) and code != "" do
    {stage, number} = stage(g["gameScreen"])

    [
      %{
        code: code,
        list: list,
        pack: pack(g["gamePack"]),
        host: get_in(g, ["host", "sporcleHandle"]),
        player_count: g["playerCount"],
        stage: stage,
        question_number: number,
        has_images: g["hasImages"] == true
      }
    ]
  end

  defp game(_game, _list), do: []

  defp players(%{player_count: n}) when is_integer(n), do: n
  defp players(_game), do: 0

  @doc """
  Where a game is, from Sporcle's `gameScreen` ("Lobby", "Question 8", "Final Question"):
  `{stage, question_number}`. A screen we haven't seen is `playing`.
  """
  def stage("Lobby"), do: {"lobby", nil}
  def stage("Final Question"), do: {"final", nil}

  def stage("Question " <> n) do
    case Integer.parse(n) do
      {number, ""} -> {"question", number}
      _ -> {"playing", nil}
    end
  end

  def stage(_screen), do: {"playing", nil}

  defp pack(%{} = p) do
    %{
      id: id(p["id"]),
      name: p["name"],
      description: p["description"],
      image_url: if(is_binary(p["img_src"]) and p["img_src"] != "", do: p["img_src"])
    }
  end

  defp pack(_), do: nil

  # Sporcle sends a joinable game's pack id as a string.
  defp id(id) when is_integer(id), do: id

  defp id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp id(_), do: nil
end
