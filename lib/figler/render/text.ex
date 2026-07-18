defmodule Figler.Render.Text do
  @moduledoc "Rendering-neutral text content, style runs, and requested fonts."

  alias Figler.Render.Font
  alias Figler.Render.Text.Run
  alias Figler.Render.Text.Source

  @enforce_keys [:content, :font]
  defstruct [:content, :font, runs: [], fallback_fonts: [], issues: []]

  @type issue :: %{required(:code) => atom(), optional(atom()) => term()}
  @type t :: %__MODULE__{
          content: String.t(),
          font: Font.t(),
          runs: [Run.t()],
          fallback_fonts: [Font.t()],
          issues: [issue()]
        }

  @doc false
  @spec from_effective(
          map(),
          Figler.Schema.NodeType.t() | :unknown,
          Source.t() | nil,
          [Figler.Render.Paint.t()]
        ) :: t() | nil
  def from_effective(node, :text, source, fill_paints) when is_map(node) do
    content = content(Map.get(node, :text))
    font = Font.from_effective(node)
    {runs, issues} = runs(content, font, fill_paints, source)

    %__MODULE__{
      content: content,
      font: font,
      runs: runs,
      fallback_fonts: if(source, do: source.fallback_fonts, else: []),
      issues: issues
    }
  end

  def from_effective(_node, _node_type, _source, _fill_paints), do: nil

  defp runs(content, font, fill_paints, nil),
    do: {base_runs(content, font, fill_paints), []}

  defp runs(content, font, fill_paints, %Source{character_style_ids: []}),
    do: {base_runs(content, font, fill_paints), []}

  defp runs(content, font, fill_paints, source) do
    codepoints = utf16_codepoints(content)
    expected_length = Enum.sum_by(codepoints, & &1.length)
    actual_length = length(source.character_style_ids)

    if expected_length == actual_length do
      styled_runs(
        codepoints,
        source.character_style_ids,
        font,
        fill_paints,
        source.style_overrides
      )
    else
      issue = %{
        code: :text_style_length_mismatch,
        expected: expected_length,
        actual: actual_length
      }

      {base_runs(content, font, fill_paints), [issue]}
    end
  end

  defp styled_runs(codepoints, style_ids, font, fill_paints, overrides) do
    case attach_style_ids(codepoints, style_ids) do
      {:ok, styled} ->
        styled
        |> Enum.chunk_by(& &1.style_id)
        |> Enum.map_reduce([], &build_run(&1, &2, font, fill_paints, overrides))
        |> then(fn {runs, issues} ->
          {runs |> merge_adjacent_runs() |> index_runs(), Enum.reverse(issues)}
        end)

      {:error, issue} ->
        {base_runs(join_codepoints(codepoints), font, fill_paints), [issue]}
    end
  end

  defp attach_style_ids(codepoints, style_ids) do
    Enum.reduce_while(codepoints, {:ok, {[], 0}}, fn codepoint, {:ok, {styled, offset}} ->
      ids = Enum.slice(style_ids, offset, codepoint.length) |> Enum.uniq()

      case ids do
        [style_id] ->
          value = Map.merge(codepoint, %{style_id: style_id, start: offset})
          {:cont, {:ok, {[value | styled], offset + codepoint.length}}}

        _mixed ->
          issue = %{code: :text_style_splits_surrogate, start: offset, length: codepoint.length}
          {:halt, {:error, issue}}
      end
    end)
    |> then(fn
      {:ok, {styled, _offset}} -> {:ok, Enum.reverse(styled)}
      error -> error
    end)
  end

  defp build_run(chunk, issues, base_font, base_paints, overrides) do
    first = hd(chunk)
    style_id = Map.fetch!(first, :style_id)
    start = Map.fetch!(first, :start)
    length = Enum.sum_by(chunk, & &1.length)
    override = if style_id == 0, do: nil, else: Map.get(overrides, style_id)

    issues =
      if style_id != 0 and is_nil(override),
        do: [missing_style(style_id, start, length) | issues],
        else: issues

    run = %Run{
      index: 0,
      start: start,
      length: length,
      content: join_codepoints(chunk),
      font: if(override, do: Font.with_overrides(base_font, override), else: base_font),
      style_id: style_id,
      fill_paints:
        if(override && override.fill_paints, do: override.fill_paints, else: base_paints),
      fill_override?: not is_nil(override && override.fill_paints),
      text_decoration: override && override.text_decoration
    }

    {run, issues}
  end

  defp merge_adjacent_runs(runs) do
    runs
    |> Enum.reduce([], fn run, merged -> merge_run(run, merged) end)
    |> Enum.reverse()
  end

  defp merge_run(run, [previous | rest]) do
    if same_style?(previous, run) do
      [
        %{
          previous
          | length: previous.length + run.length,
            content: previous.content <> run.content
        }
        | rest
      ]
    else
      [run, previous | rest]
    end
  end

  defp merge_run(run, []), do: [run]

  defp same_style?(left, right) do
    left.font == right.font and left.fill_paints == right.fill_paints and
      left.text_decoration == right.text_decoration
  end

  defp index_runs(runs),
    do: runs |> Enum.with_index() |> Enum.map(fn {run, index} -> %{run | index: index} end)

  defp missing_style(style_id, start, length) do
    %{
      code: :text_style_override_missing,
      style_id: style_id,
      run: %{start: start, length: length}
    }
  end

  defp base_runs("", _font, _fill_paints), do: []

  defp base_runs(content, font, fill_paints) do
    [
      %Run{
        index: 0,
        start: 0,
        length: utf16_length(content),
        content: content,
        font: font,
        style_id: 0,
        fill_paints: fill_paints
      }
    ]
  end

  defp utf16_codepoints(content) do
    Enum.map(String.codepoints(content), fn codepoint ->
      <<value::utf8>> = codepoint
      %{content: codepoint, length: if(value > 0xFFFF, do: 2, else: 1)}
    end)
  end

  defp utf16_length(content), do: content |> utf16_codepoints() |> Enum.sum_by(& &1.length)
  defp join_codepoints(codepoints), do: Enum.map_join(codepoints, & &1.content)
  defp content(value) when is_binary(value), do: value
  defp content(_value), do: ""
end
