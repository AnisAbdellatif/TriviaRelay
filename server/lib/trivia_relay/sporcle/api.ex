defmodule TriviaRelay.Sporcle.Api do
  @moduledoc """
  The Party REST calls a relay makes on a player's behalf: `party.sporcle.com/api/party`.

  Every call takes the player's credentials as an argument and nothing is kept
  between calls. Game creation and joining are never retried: each one reserves a
  GameLift player session.
  """

  alias TriviaRelay.Sporcle.{Cred, Http, Identity}

  @base "https://party.sporcle.com/api/party"

  # The catalog's lists, by our name: Sporcle's `type` filter and the `sort` the official
  # app sends with it (confirmed live). Each is the official app's pack-screen tab.
  @pack_lists %{
    "popular" => {"mostPopular", "play_count"},
    "fresh" => {"mostRecent", "date_desc"},
    "bookmarked" => {"bookmarked", ""},
    "created" => {"created", ""},
    "friends" => {"friends", ""},
    "purchased" => {"purchased", ""},
    "free" => {"free", ""},
    "all" => {"all", ""}
  }
  @pack_list_order ~w(popular fresh bookmarked created friends purchased free all)

  def constants, do: %{"pack_lists" => @pack_list_order}

  @doc "Pack metadata (name, question count, image); never the questions."
  def get_pack(%Cred{} = cred, pack_id) do
    with {:ok, body} <- request(cred, :get, "/getPack", params: [pack_id: pack_id]) do
      {:ok, body["pack"]}
    end
  end

  @doc """
  Creates a game of `pack` (as `get_pack/2` returned it). The response carries
  `gameCode` and the host's own `playerSession`.
  """
  def create_game(%Cred{} = cred, pack, options) do
    request(cred, :post, "/createGame", json: %{gamePack: pack, gameOptions: options})
  end

  @doc """
  Searches the pack catalog, within one of its lists (`constants/0`) or all of it (`nil`).
  Returns `{:ok, packs}`, a page of 20, each the catalog's own map (`id`, `name`,
  `description`, `img_src`, `num_questions`, `has_images`, `play_count`, …).
  """
  def search_packs(%Cred{} = cred, text, page \\ 0, list \\ nil) do
    filters =
      case @pack_lists[list] do
        {type, sort} -> %{type: type, sort: sort}
        nil -> %{}
      end

    params = [searchText: text, filters: Jason.encode!(filters), page: page]

    with {:ok, body} <- request(cred, :get, "/searchPacks", params: params) do
      data = body["data"] || body
      {:ok, data["packs"] || []}
    end
  end

  @doc "Joins a game by code; the response carries this player's `playerSession`."
  def join_game(%Cred{} = cred, code) do
    request(cred, :post, "/joinGame", json: %{gameCode: code})
  end

  defp request(cred, method, path, opts) do
    [method: method, url: @base <> path, headers: headers(cred)]
    |> Keyword.merge(opts)
    |> Http.request()
    |> case do
      {:ok, %{status: 200, body: body}} when is_map(body) -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {:http, status, body}}
      {:error, exception} -> {:error, exception}
    end
  end

  defp headers(cred) do
    %{
      "x-sporcle-api-key" => Identity.api_key(),
      "x-sporcle-bundle" => Identity.bundle(),
      "x-sporcle-player" => cred.player_id,
      "x-sporcle-token" => cred.token,
      "x-udid" => cred.device_id,
      "user-agent" => Identity.user_agent_api(),
      "version" => Identity.version(),
      "platform" => "android"
    }
  end
end
