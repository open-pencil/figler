defmodule Figler.Render.Skia.Fonts.Resolution do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Font, Skia.Typeface]}

  alias Figler.Render.Font

  @spec requested_supplied_typeface([Skia.Typeface.t()], Font.t(), [String.t()]) ::
          Skia.Typeface.t() | nil
  def requested_supplied_typeface(supplied, font, codepoints) do
    Enum.find(supplied, fn typeface ->
      typeface.family == font.family and covers?(typeface, codepoints) == {:ok, true}
    end)
  end

  @spec requested_typeface(Font.t()) :: {:ok, Skia.Typeface.t()} | {:error, term()}
  def requested_typeface(%Font{family: nil}), do: {:error, :font_family_missing}

  def requested_typeface(font),
    do: Skia.Typeface.match_family(font.family, weight: font.weight, slant: font.slant)

  @spec usable_typeface({:ok, Skia.Typeface.t()} | {:error, term()}, [String.t()]) ::
          {:ok, Skia.Typeface.t()} | {:missing, Skia.Typeface.t() | nil} | {:error, term()}
  def usable_typeface({:ok, typeface}, codepoints) do
    case covers?(typeface, codepoints) do
      {:ok, true} -> {:ok, typeface}
      {:ok, false} -> {:missing, typeface}
      {:error, reason} -> {:error, reason}
    end
  end

  def usable_typeface({:error, _reason}, _codepoints), do: {:missing, nil}

  @spec fallback(Font.t(), [Font.t()], [Skia.Typeface.t()], [String.t()], [String.t()], keyword()) ::
          {Skia.Typeface.t(), :supplied | :figma_fallback | :system} | nil
  def fallback(font, figma_fallbacks, supplied, codepoints, languages, opts) do
    matching_supplied_fallback(supplied, figma_fallbacks, codepoints) ||
      figma_fallback(figma_fallbacks, codepoints) ||
      supplied_fallback(supplied, codepoints) ||
      system_fallback(font, codepoints, languages, opts)
  end

  @spec covers?(Skia.Typeface.t(), [String.t()]) :: {:ok, boolean()} | {:error, term()}
  def covers?(_typeface, []), do: {:ok, true}

  def covers?(typeface, codepoints) do
    case glyph_ids(typeface, codepoints) do
      {:ok, glyph_ids} -> {:ok, Enum.all?(glyph_ids, &(&1 > 0))}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec missing_codepoints(Skia.Typeface.t(), [String.t()]) :: [String.t()]
  def missing_codepoints(typeface, codepoints) do
    case glyph_ids(typeface, codepoints) do
      {:ok, glyph_ids} ->
        codepoints
        |> Enum.zip(glyph_ids)
        |> Enum.flat_map(fn
          {codepoint, 0} -> [codepoint]
          {_codepoint, _glyph_id} -> []
        end)

      {:error, _reason} ->
        codepoints
    end
  end

  @spec codepoints(String.t()) :: [String.t()]
  def codepoints(text) do
    text
    |> String.codepoints()
    |> Enum.reject(&ignorable_codepoint?/1)
    |> Enum.uniq()
  end

  @spec request(Font.t()) :: map()
  def request(font) do
    %{
      family: font.family,
      style: font.style,
      postscript: font.postscript,
      weight: font.weight,
      slant: font.slant
    }
  end

  @spec codepoint_name(String.t()) :: String.t()
  def codepoint_name(<<value::utf8>>) do
    "U+" <> (value |> Integer.to_string(16) |> String.pad_leading(4, "0"))
  end

  defp matching_supplied_fallback(supplied, figma_fallbacks, codepoints) do
    families = figma_fallbacks |> Enum.map(& &1.family) |> Enum.reject(&is_nil/1) |> MapSet.new()
    supplied |> Enum.filter(&MapSet.member?(families, &1.family)) |> supplied_fallback(codepoints)
  end

  defp figma_fallback(fonts, codepoints) do
    Enum.find_value(fonts, fn font ->
      with family when is_binary(family) <- font.family,
           {:ok, typeface} <-
             Skia.Typeface.match_family(family, weight: font.weight, slant: font.slant),
           {:ok, true} <- covers?(typeface, codepoints) do
        {typeface, :figma_fallback}
      else
        _unusable -> nil
      end
    end)
  end

  defp supplied_fallback(typefaces, codepoints) do
    Enum.find_value(typefaces, fn typeface ->
      if covers?(typeface, codepoints) == {:ok, true}, do: {typeface, :supplied}
    end)
  end

  defp system_fallback(font, codepoints, languages, opts) do
    if Keyword.get(opts, :system_font_fallback, true),
      do: Enum.find_value(codepoints, &matching_system_typeface(&1, font, codepoints, languages))
  end

  defp matching_system_typeface(codepoint, font, codepoints, languages) do
    with {:ok, typeface} <-
           Skia.Typeface.match_character(codepoint,
             family: font.family || "",
             weight: font.weight,
             slant: font.slant,
             languages: languages
           ),
         {:ok, true} <- covers?(typeface, codepoints) do
      {typeface, :system}
    else
      _unusable -> nil
    end
  end

  defp glyph_ids(typeface, codepoints),
    do: typeface |> Skia.Font.new(size: 14) |> Skia.Font.glyph_ids(Enum.join(codepoints))

  defp ignorable_codepoint?(codepoint) do
    <<value::utf8>> = codepoint

    String.trim(codepoint) == "" or value <= 0x1F or value in 0x7F..0x9F or
      value in [0x200C, 0x200D] or value in 0xFE00..0xFE0F or value in 0xE0100..0xE01EF
  end
end
