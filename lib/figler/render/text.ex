defmodule Figler.Render.Text do
  @moduledoc "Rendering-neutral text content, style runs, and requested fonts."

  alias Figler.Render.Font
  alias Figler.Render.Text.Glyphs
  alias Figler.Render.Text.Measurement
  alias Figler.Render.Text.Run
  alias Figler.Render.Text.Source

  @source_fields [
    :line_height,
    :letter_spacing,
    :text_decoration,
    :text_decoration_style,
    :text_decoration_thickness,
    :text_decoration_skip_ink,
    :text_underline_offset,
    :text_decoration_fill_paints,
    :text_case,
    :text_align_horizontal,
    :text_align_vertical,
    :text_auto_resize,
    :text_truncation,
    :max_lines
  ]

  @enforce_keys [:content, :font]
  defstruct [
    :content,
    :font,
    :align_horizontal,
    :align_vertical,
    :auto_resize,
    :truncation,
    :max_lines,
    runs: [],
    glyphs: [],
    decorations: [],
    fallback_fonts: [],
    issues: []
  ]

  @type issue :: %{required(:code) => atom(), optional(atom()) => term()}
  @type t :: %__MODULE__{
          content: String.t(),
          font: Font.t(),
          align_horizontal: atom() | nil,
          align_vertical: atom() | nil,
          auto_resize: atom() | nil,
          truncation: atom() | nil,
          max_lines: non_neg_integer() | nil,
          runs: [Run.t()],
          glyphs: [Figler.Render.Text.Glyph.t()],
          decorations: [map()],
          fallback_fonts: [Font.t()],
          issues: [issue()]
        }

  @doc false
  @spec source_fields() :: [atom()]
  def source_fields, do: @source_fields

  @doc false
  @spec from_effective(
          map(),
          Figler.Schema.NodeType.t() | :unknown,
          Source.t() | nil,
          [Figler.Render.Paint.t()]
        ) :: t() | nil
  def from_effective(node, type, source, fill_paints)
      when type in [:text, :text_path] and is_map(node) do
    content = content(Map.get(node, :text))
    font = Font.from_effective(node)
    base_style = base_style(node)
    {runs, issues} = runs(content, font, fill_paints, source, base_style)
    {glyphs, decorations} = Glyphs.from_derived(Map.get(node, :derived_text_data), content)

    %__MODULE__{
      content: content,
      font: font,
      align_horizontal: Map.get(node, :text_align_horizontal),
      align_vertical: Map.get(node, :text_align_vertical),
      auto_resize: Map.get(node, :text_auto_resize),
      truncation: Map.get(node, :text_truncation),
      max_lines: Map.get(node, :max_lines),
      runs: runs,
      glyphs: glyphs,
      decorations: decorations,
      fallback_fonts: if(source, do: source.fallback_fonts, else: []),
      issues: issues
    }
  end

  def from_effective(_node, _node_type, _source, _fill_paints), do: nil

  defp runs(content, font, fill_paints, nil, base_style),
    do: {base_runs(content, font, fill_paints, base_style), []}

  defp runs(content, font, fill_paints, %Source{character_style_ids: []}, base_style),
    do: {base_runs(content, font, fill_paints, base_style), []}

  defp runs(content, font, fill_paints, source, base_style) do
    codepoints = utf16_codepoints(content)
    expected_length = Enum.sum_by(codepoints, & &1.length)
    actual_length = length(source.character_style_ids)

    if expected_length == actual_length do
      styled_runs(
        codepoints,
        source.character_style_ids,
        font,
        fill_paints,
        source.style_overrides,
        base_style
      )
    else
      issue = %{
        code: :text_style_length_mismatch,
        expected: expected_length,
        actual: actual_length
      }

      {base_runs(content, font, fill_paints, base_style), [issue]}
    end
  end

  defp styled_runs(codepoints, style_ids, font, fill_paints, overrides, base_style) do
    case attach_style_ids(codepoints, style_ids) do
      {:ok, styled} ->
        styled
        |> Enum.chunk_by(& &1.style_id)
        |> Enum.map_reduce([], &build_run(&1, &2, font, fill_paints, overrides, base_style))
        |> then(fn {runs, issues} ->
          {runs |> merge_adjacent_runs() |> index_runs(), Enum.reverse(issues)}
        end)

      {:error, issue} ->
        {base_runs(join_codepoints(codepoints), font, fill_paints, base_style), [issue]}
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

  defp build_run(chunk, issues, base_font, base_paints, overrides, base_style) do
    first = hd(chunk)
    style_id = Map.fetch!(first, :style_id)
    start = Map.fetch!(first, :start)
    length = Enum.sum_by(chunk, & &1.length)
    override = if style_id == 0, do: nil, else: Map.get(overrides, style_id)

    issues =
      if style_id != 0 and is_nil(override),
        do: [missing_style(style_id, start, length) | issues],
        else: issues

    font = if override, do: Font.with_overrides(base_font, override), else: base_font

    run = %Run{
      index: 0,
      start: start,
      length: length,
      content: join_codepoints(chunk),
      font: font,
      style_id: style_id,
      fill_paints:
        if(override && override.fill_paints, do: override.fill_paints, else: base_paints),
      fill_override?: not is_nil(override && override.fill_paints),
      line_height:
        style_measurement(override, base_style, :line_height)
        |> Measurement.pixels(font.size, :line_height),
      letter_spacing:
        style_measurement(override, base_style, :letter_spacing)
        |> Measurement.pixels(font.size, :letter_spacing),
      text_decoration: style_value(override, base_style, :text_decoration),
      text_decoration_style: style_value(override, base_style, :text_decoration_style),
      text_decoration_thickness: style_value(override, base_style, :text_decoration_thickness),
      text_decoration_skip_ink: style_value(override, base_style, :text_decoration_skip_ink),
      text_underline_offset: style_value(override, base_style, :text_underline_offset),
      text_decoration_fill_paints:
        style_value(override, base_style, :text_decoration_fill_paints) || [],
      text_case: style_value(override, base_style, :text_case)
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

  defp same_style?(left, right), do: style_signature(left) == style_signature(right)

  defp style_signature(run) do
    {
      run.font,
      run.fill_paints,
      run.line_height,
      run.letter_spacing,
      run.text_decoration,
      run.text_decoration_style,
      run.text_decoration_thickness,
      run.text_decoration_skip_ink,
      run.text_underline_offset,
      run.text_decoration_fill_paints,
      run.text_case
    }
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

  defp base_runs("", _font, _fill_paints, _base_style), do: []

  defp base_runs(content, font, fill_paints, base_style) do
    [
      %Run{
        index: 0,
        start: 0,
        length: utf16_length(content),
        content: content,
        font: font,
        style_id: 0,
        line_height: Measurement.pixels(base_style.line_height, font.size, :line_height),
        letter_spacing: Measurement.pixels(base_style.letter_spacing, font.size, :letter_spacing),
        text_decoration: base_style.text_decoration,
        text_decoration_style: base_style.text_decoration_style,
        text_decoration_thickness: base_style.text_decoration_thickness,
        text_decoration_skip_ink: base_style.text_decoration_skip_ink,
        text_underline_offset: base_style.text_underline_offset,
        text_decoration_fill_paints: base_style.text_decoration_fill_paints || [],
        text_case: base_style.text_case,
        fill_paints: fill_paints
      }
    ]
  end

  defp base_style(node) do
    %{
      line_height: line_height(node),
      letter_spacing: Measurement.from_sparse(Map.get(node, :letter_spacing)),
      text_decoration: Map.get(node, :text_decoration),
      text_decoration_style: Map.get(node, :text_decoration_style),
      text_decoration_thickness: Map.get(node, :text_decoration_thickness),
      text_decoration_skip_ink: Map.get(node, :text_decoration_skip_ink),
      text_underline_offset: Map.get(node, :text_underline_offset),
      text_decoration_fill_paints: Map.get(node, :text_decoration_fill_paints),
      text_case: Map.get(node, :text_case)
    }
  end

  # Figma saves each line at the larger of its line height and its tallest font's height, so a
  # first line shorter than the text's height in pixels was laid out at one a style set.
  defp line_height(node) do
    line_height = Measurement.from_sparse(Map.get(node, :line_height))

    case get_in(node, [:derived_text_data, :baselines]) do
      [%{line_height: derived} | _]
      when is_number(derived) and is_struct(line_height, Measurement) and
             line_height.units == :pixels and derived < line_height.value ->
        %Measurement{value: derived * 1.0, units: :pixels}

      _saved ->
        line_height
    end
  end

  defp style_measurement(nil, base_style, field), do: Map.get(base_style, field)

  defp style_measurement(override, base_style, field),
    do: Map.get(override, field) || Map.get(base_style, field)

  defp style_value(nil, base_style, field), do: Map.get(base_style, field)

  defp style_value(override, base_style, field) do
    case Map.get(override, field) do
      nil -> Map.get(base_style, field)
      value -> value
    end
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
