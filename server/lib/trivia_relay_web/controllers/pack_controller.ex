defmodule TriviaRelayWeb.PackController do
  @moduledoc """
  `GET /api/packs?q=…&list=…&page=…` (`protocol/PROTOCOL.md` §3.2): Sporcle's pack search,
  within one of its lists or all of it, made with the caller's credentials. They come in
  headers, never the URL, which proxies log.
  """

  use TriviaRelayWeb, :controller

  alias TriviaRelay.Sporcle.{Api, Cred}
  alias TriviaRelayWeb.{ApiError, SporcleErrors}

  def index(conn, params) do
    page = parse_page(params["page"])

    with {:ok, cred} <- Cred.new(player(conn)),
         {:ok, list} <- list(params["list"]),
         query = String.slice(params["q"] || "", 0, 100),
         {:ok, packs} <- Api.search_packs(cred, query, page, list) do
      # An empty page is the end of the list.
      json(conn, %{packs: Enum.map(packs, &pack/1), next_page: if(packs != [], do: page + 1)})
    else
      :invalid_list ->
        ApiError.send(conn, :bad_request, "invalid_list", "That list of packs doesn't exist.")

      error ->
        SporcleErrors.send(conn, error)
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

  defp pack(p) do
    %{
      id: p["id"],
      name: p["name"],
      description: p["description"],
      image_url: image(p["img_src"]),
      num_questions: p["num_questions"],
      has_images: p["has_images"] == true,
      play_count: p["play_count"]
    }
  end

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
