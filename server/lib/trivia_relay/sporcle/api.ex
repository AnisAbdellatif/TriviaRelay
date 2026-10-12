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

  # The official app's join screen, by our name: the lists `getJoinableGames` answers with
  # (confirmed live), in the order they're shown.
  @game_lists [
    {"invited", "invitedGames"},
    {"friends", "friendGames"},
    {"public", "publicGames"}
  ]

  # What the official app's "Report Pack" offers, by value (decompiled only).
  @report_reasons ~w(harassment offensive spam inaccurate other)

  def constants,
    do: %{
      "pack_lists" => @pack_list_order,
      "game_lists" => Enum.map(@game_lists, &elem(&1, 0)),
      "pack_report_reasons" => @report_reasons
    }

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

  @doc """
  The games this player could join, as the official app's join screen lists them. Returns
  `{:ok, [{list, games}]}` in `constants/0`'s order, each game the map Sporcle sent
  (`gameCode`, `gamePack`, `gameScreen`, `host`, `playerCount`, …).
  """
  def joinable_games(%Cred{} = cred) do
    with {:ok, body} <- request(cred, :get, "/getJoinableGames", []) do
      data = body["data"] || body
      {:ok, for({list, key} <- @game_lists, do: {list, List.wrap(data[key])})}
    end
  end

  @doc """
  Joins a game by code. The response carries this player's `playerSession` and their
  `popper_count`, or, when Sporcle won't seat them, `denied: {code, message}` and no
  session (`BuyPopper` for a game with images and no Party Popper left).
  """
  def join_game(%Cred{} = cred, code) do
    request(cred, :post, "/joinGame", json: %{gameCode: code})
  end

  @doc "What a pack may be reported for, as the official app offers it."
  def report_reasons, do: @report_reasons

  @doc "A pack the catalog picks at random, the catalog's own map as `get_pack/2` gives it."
  def random_pack(%Cred{} = cred) do
    with {:ok, body} <- request(cred, :get, "/getRandomPack", params: []) do
      {:ok, data(body)["pack"]}
    end
  end

  @doc """
  Bookmarks pack `pack_id` (`bookmarked` true) or stops bookmarking it. The official app
  sends the pack's state *before* the tap and Sporcle turns it over (decompiled only),
  so what is sent is the opposite of what is asked for.
  """
  def bookmark_pack(%Cred{} = cred, pack_id, bookmarked) when is_boolean(bookmarked) do
    request(cred, :post, "/bookmarkPack", json: %{pack_id: pack_id, bookmarked: !bookmarked})
  end

  @doc """
  Subscribes to pack `pack_id` (Sporcle then tells the player, in its own app, when
  somebody hosts it) or stops. The flag is sent as `bookmark_pack/3` sends its own.
  """
  def subscribe_pack(%Cred{} = cred, pack_id, subscribed) when is_boolean(subscribed) do
    request(cred, :post, "/subscribePack", json: %{pack_id: pack_id, subscribed: !subscribed})
  end

  @doc "Reports pack `pack_id` to Sporcle for one of `report_reasons/0`, in the player's words."
  def report_pack(%Cred{} = cred, pack_id, reason, details) when reason in @report_reasons do
    request(cred, :post, "/reportPack",
      json: %{pack_id: pack_id, reason: reason, extraInfoText: details}
    )
  end

  @doc """
  Claims the Party Poppers the player has earned back (one every 4 hours, up to 5).
  Answers `{popper_count, popper_last_claim}` whether or not there were any to claim.
  """
  def claim_poppers(%Cred{} = cred) do
    with {:ok, body} <- request(cred, :post, "/claimPoppers", json: %{}), do: {:ok, data(body)}
  end

  @doc """
  A page of the player's friends: `{:ok, friends}`, Sporcle's map of them by the id an
  invitation takes, each a player map (`playerId`, `sporcleHandle`, `teamName`,
  `friendStatus`, …).
  """
  def friends(%Cred{} = cred, page \\ 0) do
    with {:ok, body} <- request(cred, :get, "/getFriends", params: [page: page]) do
      {:ok, data(body)["friends"] || %{}}
    end
  end

  @doc """
  Invites one friend (`friend_id`, as `friends/2` keys them) to `game`, or every friend
  with `:all`. `game` is `%{gameCode, gamePack: %{id, name, img_src}}`, as the official
  app sends it.
  """
  def invite(%Cred{} = cred, :all, game),
    do: request(cred, :post, "/inviteAllFriendsToGame", json: %{game: game})

  def invite(%Cred{} = cred, friend_id, game) when is_binary(friend_id),
    do: request(cred, :post, "/inviteToGame", json: %{friend_uid: friend_id, game: game})

  @doc "Whether Sporcle finds words it won't show in `name`: `{:ok, boolean}`."
  def name_has_bad_words(%Cred{} = cred, name) do
    with {:ok, body} <- request(cred, :get, "/getHandleHasBadWords", params: [handle: name]) do
      {:ok, data(body)["handle_has_bad_words"] == true}
    end
  end

  # Most answers are the payload itself; some have come wrapped in `data`.
  defp data(%{"data" => %{} = data}), do: data
  defp data(body), do: body

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
