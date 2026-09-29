defmodule TriviaRelayWeb.ChannelCase do
  @moduledoc "Channel tests: a seat to join, and a way to play Sporcle's side of it."

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import TriviaRelayWeb.ChannelCase

      @endpoint TriviaRelayWeb.Endpoint
    end
  end

  alias TriviaRelay.Seats.Seat

  @doc """
  Starts a seat under the seats supervisor with a fake upstream, as `Seats` would after
  joinGame. Returns `%{id, token, seat, upstream, me}`.

  Each seat is a different player (`:me`) unless the test says otherwise: a player has one
  seat at a time, and a new one ends the old.
  """
  def start_seat(opts \\ []) do
    unique = Integer.to_string(System.unique_integer([:positive]))
    id = "seat" <> unique
    {me, opts} = Keyword.pop(opts, :me, "sporcle_id//joinPlayer" <> unique)

    spec =
      {Seat,
       Keyword.merge(
         [
           id: id,
           game_code: "624949",
           me: me,
           session: %{
             "test_pid" => self(),
             "DnsName" => "x",
             "Port" => 1,
             "PlayerSessionId" => "psess-x"
           },
           player: %{}
         ],
         opts
       )}

    {:ok, seat} = DynamicSupervisor.start_child(TriviaRelay.Seats.Supervisor, spec)
    upstream = receive do: ({:fake_upstream, pid, ^seat, _} -> pid)
    %{id: id, token: TriviaRelay.Seats.sign(id), seat: seat, upstream: upstream, me: me}
  end

  @doc "Plays Sporcle's side: the seat's upstream received `event`."
  def sporcle(seat, event, payload), do: send(seat, {:upstream, "test", {:event, event, payload}})

  @doc "A lobby with the host (peer 1) and this seat's player (peer 2), five questions of 15 s."
  def lobby(seat) do
    me = :sys.get_state(seat).state.me

    sporcle(seat, "game_info", %{
      "allPlayers" => [player(1, "sporcle_id//hostPlayer", true), player(2, me, false)],
      "gameOptions" => %{"QUESTIONS_PER_GAME" => 5, "QUESTION_SECONDS" => 15},
      "gamePack" => %{"id" => 156_070, "name" => "Flags", "num_questions" => 169}
    })
  end

  def player(peer, id, host?) do
    %{
      "peerId" => peer,
      "playerId" => id,
      "teamName" => "P#{peer}",
      "isHost" => host?,
      "score" => 0
    }
  end
end
