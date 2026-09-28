defmodule Mix.Tasks.Spike do
  @shortdoc "Play a Sporcle Party game from the terminal, logging every frame"

  @moduledoc """
  Hosts or joins one Sporcle Party game as one player, from an interactive console,
  and writes every frame to `logs/`.

      mix spike host --cred host --pack 268682 --audience private [--seconds 45] [--questions 10]
      mix spike join ABCD --cred join

  `--cred NAME` reads `creds/NAME.json` (README). Type `help` at the prompt for commands.
  """

  use Mix.Task

  alias TriviaRelay.Seats.Intents
  alias TriviaRelay.Spike.Session
  alias TriviaRelay.Sporcle.{Cred, FrameLog}

  @switches [
    cred: :string,
    pack: :integer,
    seconds: :integer,
    questions: :integer,
    audience: :string
  ]

  @impl true
  def run(argv) do
    {opts, args} = OptionParser.parse!(argv, strict: @switches)
    Mix.Task.run("app.start")

    cred_name = opts[:cred] || Mix.raise("--cred NAME is required (creds/NAME.json)")
    cred = load!(cred_name)
    role_opts = role(args, opts)

    stamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d-%H%M%S")
    {:ok, log} = FrameLog.start_link("#{stamp}-#{role_opts[:role]}-#{cred_name}")
    IO.puts("logging to #{FrameLog.path(log)}")

    case Session.start_link([cred: cred, log: log] ++ role_opts) do
      {:ok, session} ->
        IO.puts("type `help` for commands")
        loop(session)

      {:error, reason} ->
        Mix.raise("could not start: #{inspect(reason)}")
    end
  end

  defp load!(name) do
    case Cred.load(name) do
      {:ok, cred} -> cred
      {:error, message} -> Mix.raise(message)
    end
  end

  defp role(["host"], opts) do
    [
      role: :host,
      pack: opts[:pack] || Mix.raise("host needs --pack ID"),
      # "anyone" lists the game publicly: strangers join within seconds. Required, so a
      # public game is never made by default.
      options:
        Intents.game_options(
          opts[:questions] || 10,
          opts[:seconds] || 45,
          opts[:audience] || Mix.raise("host needs --audience private|friends|anyone")
        )
    ]
  end

  defp role(["join", code], _opts), do: [role: :join, code: String.upcase(code)]

  defp role(_, _) do
    Mix.raise(
      "usage: mix spike host --cred NAME --pack ID --audience TYPE | mix spike join CODE --cred NAME"
    )
  end

  defp loop(session) do
    case IO.gets("") do
      line when is_binary(line) ->
        if String.trim(line) not in ["quit", "exit"] do
          run_line(session, line)
          loop(session)
        end

      _eof_or_error ->
        :ok
    end
  end

  defp run_line(session, line) do
    case Session.command(session, line) do
      :ok -> :ok
      {:print, text} -> IO.write(text)
      {:error, reason} -> IO.puts("! #{format(reason)}")
    end
  end

  defp format(reason) when is_binary(reason), do: reason
  defp format(reason), do: inspect(reason)
end
