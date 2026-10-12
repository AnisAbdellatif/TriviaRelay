defmodule TriviaRelayWeb.PackController do
  @moduledoc """
  The pack catalog, asked with the caller's credentials (`protocol/PROTOCOL.md` §3.2).
  They come in headers, never the URL, which proxies log.

    * `GET /api/packs?q=…&list=…&page=…`: Sporcle's pack search, within one of its lists
      or all of it.
    * `GET /api/packs/random`: a pack the catalog picks (since 1.2).
    * `GET /api/packs/:id`: one pack, with whether this player bookmarked and subscribed
      to it (since 1.2).
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Cache
  alias TriviaRelay.Sporcle.{Api, Cred}
  alias TriviaRelayWeb.{ApiError, SporcleErrors}

  # The lists that are the same for everybody, browsed without a search: kept a minute
  # (TriviaRelay.Cache), since every host opens on them. Anything searched, or a list of
  # the player's own (bookmarked, created, …), is asked of Sporcle every time. What a
  # pack says of the player who asked (bookmarked, subscribed) is never kept: a kept
  # list carries none of it.
  @shared_lists ~w(popular fresh)
  @shared_ttl_ms 60_000

  def index(conn, %{"q" => q}) when not is_binary(q),
    do: ApiError.send(conn, :bad_request, "invalid_request", "Search for some text.")

  def index(conn, params) do
    page = parse_page(params["page"])

    with {:ok, cred} <- Cred.new(player(conn)),
         {:ok, list} <- list(params["list"]),
         query = String.slice(params["q"] || "", 0, 100),
         {:ok, packs} <- search(cred, query, page, list) do
      # An empty page is the end of the list.
      json(conn, %{packs: packs, next_page: if(packs != [], do: page + 1)})
    else
      :invalid_list ->
        ApiError.send(conn, :bad_request, "invalid_list", "That list of packs doesn't exist.")

      error ->
        SporcleErrors.send(conn, error)
    end
  end

  @doc "`GET /api/packs/:id`: the pack, as the player sees it."
  def show(conn, %{"id" => id}) do
    with {:ok, pack_id} <- pack_id(id),
         {:ok, cred} <- Cred.new(player(conn)),
         {:ok, pack} <- Api.get_pack(cred, pack_id),
         %{"id" => _} <- pack do
      json(conn, %{pack: summary(pack, :personal)})
    else
      error -> not_found_or(conn, error)
    end
  end

  @doc "`GET /api/packs/random`: whatever pack the catalog picks this time."
  def random(conn, _params) do
    with {:ok, cred} <- Cred.new(player(conn)),
         {:ok, %{"id" => _} = pack} <- Api.random_pack(cred) do
      json(conn, %{pack: summary(pack, :personal)})
    else
      error -> not_found_or(conn, error)
    end
  end

  defp not_found_or(conn, error) do
    case error do
      {:error, {:http, status, _}} when status in [400, 404] ->
        SporcleErrors.send(conn, {:error, :pack_not_found})

      {:error, _} ->
        SporcleErrors.send(conn, error)

      _ ->
        SporcleErrors.send(conn, {:error, :pack_not_found})
    end
  end

  defp search(cred, "", page, list) when list in @shared_lists do
    Cache.fetch({:packs, list, page}, @shared_ttl_ms, fn ->
      search_now(cred, "", page, list, :shared)
    end)
  end

  defp search(cred, query, page, list), do: search_now(cred, query, page, list, :personal)

  defp search_now(cred, query, page, list, whose) do
    with {:ok, packs} <- Api.search_packs(cred, query, page, list) do
      {:ok, Enum.map(packs, &summary(&1, whose))}
    end
  end

  @doc "A phone's Sporcle credentials, from the `x-player-*` headers."
  def player(conn) do
    %{
      "player_id" => header(conn, "x-player-id"),
      "token" => header(conn, "x-player-token"),
      "device_id" => header(conn, "x-device-id"),
      "handle" => header(conn, "x-player-handle")
    }
  end

  @doc """
  A pack id from a path: digits, a positive integer. `{:ok, id}` or
  `{:error, :pack_not_found}`.
  """
  def pack_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 and n < 10_000_000_000 -> {:ok, n}
      _ -> {:error, :pack_not_found}
    end
  end

  def pack_id(_), do: {:error, :pack_not_found}

  # A pack as §3.2 describes it. `:personal` carries what it says of the player who
  # asked; `:shared` (kept, and served to everybody) never does.
  defp summary(p, whose) do
    %{
      id: p["id"],
      name: p["name"],
      description: p["description"],
      image_url: image(p["img_src"]),
      num_questions: p["num_questions"],
      has_images: p["has_images"] == true,
      play_count: p["play_count"],
      bookmarked: personal(p["bookmarked"], whose),
      subscribed: personal(p["subscribed"], whose)
    }
  end

  defp personal(flag, :personal) when is_boolean(flag), do: flag
  defp personal(_flag, _whose), do: nil

  defp list(nil), do: {:ok, nil}

  defp list(list),
    do: if(list in Api.constants()["pack_lists"], do: {:ok, list}, else: :invalid_list)

  # Sporcle sends an empty string for a pack without an image.
  defp image(url) when is_binary(url) and url != "", do: url
  defp image(_), do: nil

  defp header(conn, name), do: conn |> get_req_header(name) |> List.first()

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {n, ""} when n >= 0 and n < 1000 -> n
      _ -> 0
    end
  end

  defp parse_page(_), do: 0
end
