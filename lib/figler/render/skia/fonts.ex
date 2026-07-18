defmodule Figler.Render.Skia.Fonts do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Font, Skia.Typeface]}

  alias Figler.Render.Font
  alias Figler.Render.Node
  alias Figler.Render.Text

  @type warning_value :: %{
          required(:code) =>
            :font_family_missing | :font_unavailable | :font_inspection_failed | :glyphs_missing,
          optional(atom()) => term()
        }

  @spec diagnose([Node.t()]) :: %{optional(tuple()) => [warning_value()]}
  def diagnose(nodes) do
    nodes
    |> Enum.filter(&text_node?/1)
    |> Enum.group_by(&font_key/1)
    |> Enum.reduce(%{}, &diagnose_font_group/2)
  end

  defp text_node?(%Node{node_type: :text, text: %Text{content: content}}),
    do: content != ""

  defp text_node?(_node), do: false

  defp font_key(%Node{text: %Text{font: %Font{} = font}}),
    do: {font.family, font.weight, font.slant}

  defp diagnose_font_group({{nil, _weight, _slant}, nodes}, warnings) do
    Enum.reduce(nodes, warnings, fn node, diagnosed ->
      put_warning(diagnosed, node.guid, %{
        code: :font_family_missing,
        requested: request(node.text.font)
      })
    end)
  end

  defp diagnose_font_group({{family, weight, slant}, nodes}, warnings) do
    case Skia.Typeface.match_family(family, weight: weight, slant: slant) do
      {:ok, typeface} -> diagnose_glyphs(nodes, typeface, warnings)
      {:error, reason} -> unavailable_warnings(nodes, reason, warnings)
    end
  end

  defp unavailable_warnings(nodes, reason, warnings) do
    Enum.reduce(nodes, warnings, fn node, diagnosed ->
      put_warning(diagnosed, node.guid, %{
        code: :font_unavailable,
        reason: reason,
        requested: request(node.text.font)
      })
    end)
  end

  defp diagnose_glyphs(nodes, typeface, warnings) do
    codepoints = nodes |> Enum.flat_map(&codepoints(&1.text.content)) |> Enum.uniq()
    font = Skia.Font.new(typeface, size: 14)

    case Skia.Font.glyph_ids(font, Enum.join(codepoints)) do
      {:ok, glyph_ids} -> missing_glyph_warnings(nodes, codepoints, glyph_ids, warnings)
      {:error, reason} -> inspection_warnings(nodes, reason, warnings)
    end
  end

  defp missing_glyph_warnings(nodes, codepoints, glyph_ids, warnings) do
    missing =
      codepoints
      |> Enum.zip(glyph_ids)
      |> Enum.reduce(MapSet.new(), fn
        {codepoint, 0}, missing -> MapSet.put(missing, codepoint)
        {_codepoint, _glyph_id}, missing -> missing
      end)

    Enum.reduce(nodes, warnings, fn node, diagnosed ->
      node_missing =
        node.text.content
        |> codepoints()
        |> Enum.filter(&MapSet.member?(missing, &1))
        |> Enum.uniq()

      if node_missing == [] do
        diagnosed
      else
        put_warning(diagnosed, node.guid, %{
          code: :glyphs_missing,
          characters: node_missing,
          codepoints: Enum.map(node_missing, &codepoint_name/1),
          requested: request(node.text.font)
        })
      end
    end)
  end

  defp inspection_warnings(nodes, reason, warnings) do
    Enum.reduce(nodes, warnings, fn node, diagnosed ->
      put_warning(diagnosed, node.guid, %{
        code: :font_inspection_failed,
        reason: reason,
        requested: request(node.text.font)
      })
    end)
  end

  defp request(font) do
    %{
      family: font.family,
      style: font.style,
      postscript: font.postscript,
      weight: font.weight,
      slant: font.slant
    }
  end

  defp codepoints(text) do
    text
    |> String.codepoints()
    |> Enum.reject(&ignorable_codepoint?/1)
  end

  defp ignorable_codepoint?(codepoint) do
    <<value::utf8>> = codepoint

    String.trim(codepoint) == "" or value <= 0x1F or value in 0x7F..0x9F or
      value in [0x200C, 0x200D] or value in 0xFE00..0xFE0F or value in 0xE0100..0xE01EF
  end

  defp codepoint_name(<<value::utf8>>) do
    "U+" <> (value |> Integer.to_string(16) |> String.pad_leading(4, "0"))
  end

  defp put_warning(warnings, guid, warning),
    do: Map.update(warnings, guid, [warning], &[warning | &1])
end
