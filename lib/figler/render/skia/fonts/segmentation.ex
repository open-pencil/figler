defmodule Figler.Render.Skia.Fonts.Segmentation do
  @moduledoc false

  alias Figler.Render.Text.Case, as: TextCase
  alias Figler.Render.Text.Run

  @spec display_run(Run.t()) :: Run.t()
  def display_run(%Run{} = run),
    do: %{run | content: TextCase.apply(run.content, run.text_case)}

  @spec grapheme_runs(Run.t()) :: [{Run.t(), non_neg_integer()}]
  def grapheme_runs(%Run{} = run) do
    {runs, _offset} =
      run.content
      |> TextCase.transform_graphemes(run.text_case)
      |> Enum.with_index()
      |> Enum.map_reduce(run.start, fn {{source_content, display_content}, cluster_index},
                                       start ->
        length = utf16_length(source_content)
        segmented = %{run | start: start, length: length, content: display_content}
        {{segmented, cluster_index}, start + length}
      end)

    runs
  end

  defp utf16_length(content) do
    Enum.reduce(String.codepoints(content), 0, fn codepoint, length ->
      <<value::utf8>> = codepoint
      length + if(value > 0xFFFF, do: 2, else: 1)
    end)
  end
end
