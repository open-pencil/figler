defmodule Figler.Render.Text.Case do
  @moduledoc false

  @word_grapheme ~r/[\p{L}\p{N}]/u

  @spec apply(String.t(), atom() | nil) :: String.t()
  def apply(content, text_case) do
    content
    |> transform_graphemes(text_case)
    |> Enum.map_join(&elem(&1, 1))
  end

  @spec transform_graphemes(String.t(), atom() | nil) :: [{String.t(), String.t()}]
  def transform_graphemes(content, :title) do
    {graphemes, _word_start?} =
      content
      |> String.graphemes()
      |> Enum.map_reduce(true, fn grapheme, word_start? ->
        cond do
          Regex.match?(@word_grapheme, grapheme) and word_start? ->
            {{grapheme, String.upcase(grapheme)}, false}

          Regex.match?(@word_grapheme, grapheme) ->
            {{grapheme, grapheme}, false}

          true ->
            {{grapheme, grapheme}, true}
        end
      end)

    graphemes
  end

  def transform_graphemes(content, text_case) do
    Enum.map(String.graphemes(content), fn grapheme ->
      {grapheme, transform_grapheme(grapheme, text_case)}
    end)
  end

  @spec supported?(atom() | nil) :: boolean()
  def supported?(text_case), do: text_case in [nil, :original, :upper, :lower, :title]

  defp transform_grapheme(grapheme, :upper), do: String.upcase(grapheme)
  defp transform_grapheme(grapheme, :lower), do: String.downcase(grapheme)
  defp transform_grapheme(grapheme, _text_case), do: grapheme
end
