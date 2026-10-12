defmodule TriviaRelay.Text do
  @moduledoc """
  Text a person wrote that the relay passes on to other people: a display name, a chat
  message. Kept as a person could have typed it — letters, marks and numbers of any
  script, punctuation, symbols (emoji), single spaces — and cleared of what only moves or
  hides text: control characters, bidi overrides and isolates, zero-width characters, and
  marks stacked past a few.
  """

  @doc "`text` cleaned and cut to `max` characters; \"\" when nothing is left."
  def clean(text, max) when is_binary(text) do
    if String.valid?(text) do
      text
      |> String.replace(~r/[\x{09}-\x{0D}\x{85}\x{2028}\x{2029}]/u, " ")
      |> String.replace(~r/[^\p{L}\p{M}\p{N}\p{P}\p{S}\p{Zs}]/u, "")
      |> String.replace(~r/(\p{M}{3})\p{M}+/u, "\\1")
      |> String.replace(~r/\p{Zs}+/u, " ")
      |> String.trim()
      |> String.slice(0, max)
      |> String.trim()
    else
      ""
    end
  end

  def clean(_text, _max), do: ""
end
