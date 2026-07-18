defmodule Figler.Render.Skia.Fonts.Diagnostics do
  @moduledoc false

  @spec finalize(map()) :: map()
  def finalize(result) do
    warnings =
      Map.new(result.warnings, fn {guid, values} ->
        values = values |> Enum.sort_by(&{&1.run.start, &1.run.index}) |> merge_warnings()
        {guid, values}
      end)

    %{result | warnings: warnings}
  end

  defp merge_warnings(warnings) do
    warnings
    |> Enum.reduce([], fn warning, merged -> merge_warning(warning, merged) end)
    |> Enum.reverse()
  end

  defp merge_warning(warning, [previous | rest]) do
    if mergeable_warning?(previous, warning) do
      run = %{previous.run | length: previous.run.length + warning.run.length}
      [%{previous | run: run} | rest]
    else
      [warning, previous | rest]
    end
  end

  defp merge_warning(warning, []), do: [warning]

  defp mergeable_warning?(left, right) do
    Map.delete(left, :run) == Map.delete(right, :run) and
      left.run.index == right.run.index and left.run.start + left.run.length == right.run.start
  end
end
