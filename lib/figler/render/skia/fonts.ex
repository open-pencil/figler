defmodule Figler.Render.Skia.Fonts do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Font, Skia.Typeface]}

  alias Figler.Render.Font
  alias Figler.Render.Node
  alias Figler.Render.Text
  alias Figler.Render.Text.Run

  defmodule Resolved do
    @moduledoc false

    defstruct [:font, :family, :source]

    @type t :: %__MODULE__{
            font: Skia.Font.t(),
            family: String.t() | nil,
            source: :requested | :supplied | :figma_fallback | :system
          }
  end

  @type font_key :: {tuple(), non_neg_integer()}
  @type warning_value :: %{
          required(:code) =>
            :font_family_missing
            | :font_unavailable
            | :font_inspection_failed
            | :font_substituted
            | :glyphs_missing,
          required(:run) => map(),
          optional(atom()) => term()
        }

  @type result :: %{
          fonts: %{optional(font_key()) => Resolved.t()},
          warnings: %{optional(tuple()) => [warning_value()]}
        }

  @spec resolve([Node.t()], keyword()) :: {:ok, result()} | {:error, term()}
  def resolve(nodes, opts) do
    with {:ok, supplied} <- supplied_typefaces(opts),
         {:ok, languages} <- languages(opts) do
      groups = nodes |> text_entries() |> Enum.group_by(&resolution_key/1)

      result =
        Enum.reduce(groups, %{fonts: %{}, warnings: %{}}, fn {_key, group}, resolved ->
          resolve_group(group, supplied, languages, opts, resolved)
        end)

      {:ok, sort_warnings(result)}
    end
  end

  defp sort_warnings(result) do
    warnings =
      Map.new(result.warnings, fn {guid, values} ->
        {guid, Enum.sort_by(values, & &1.run.index)}
      end)

    %{result | warnings: warnings}
  end

  defp text_entries(nodes) do
    Enum.flat_map(nodes, fn
      %Node{node_type: :text, text: %Text{} = text} = node ->
        text.runs
        |> Enum.reject(&(&1.content == ""))
        |> Enum.map(&%{node: node, text: text, run: &1})

      _node ->
        []
    end)
  end

  defp resolution_key(%{text: text, run: run}) do
    font = run.font

    {
      font.family,
      font.style,
      font.postscript,
      font.weight,
      font.slant,
      codepoints(run.content),
      Enum.map(text.fallback_fonts, &{&1.family, &1.weight, &1.slant})
    }
  end

  defp resolve_group([representative | _] = entries, supplied, languages, opts, result) do
    font = representative.run.font
    codepoints = codepoints(representative.run.content)

    case requested_supplied_typeface(supplied, font, codepoints) do
      nil ->
        resolve_system_requested(
          result,
          entries,
          representative,
          font,
          codepoints,
          supplied,
          languages,
          opts
        )

      typeface ->
        put_resolutions(result, entries, typeface, :supplied)
    end
  end

  defp resolve_system_requested(
         result,
         entries,
         representative,
         font,
         codepoints,
         supplied,
         languages,
         opts
       ) do
    case font |> requested_typeface() |> usable_typeface(codepoints) do
      {:ok, typeface} ->
        put_resolutions(result, entries, typeface, :requested)

      {:missing, requested_typeface} ->
        resolve_fallback(
          result,
          entries,
          representative,
          codepoints,
          requested_typeface,
          supplied,
          languages,
          opts
        )

      {:error, reason} ->
        put_group_warning(result, entries, %{
          code: :font_inspection_failed,
          reason: reason,
          requested: request(font)
        })
    end
  end

  defp requested_supplied_typeface(supplied, font, codepoints) do
    Enum.find(supplied, fn typeface ->
      typeface.family == font.family and covers?(typeface, codepoints) == {:ok, true}
    end)
  end

  defp resolve_fallback(
         result,
         entries,
         representative,
         codepoints,
         requested,
         supplied,
         languages,
         opts
       ) do
    font = representative.run.font
    figma_fallbacks = representative.text.fallback_fonts

    fallback =
      matching_supplied_fallback(supplied, figma_fallbacks, codepoints) ||
        figma_fallback(figma_fallbacks, codepoints) ||
        supplied_fallback(supplied, codepoints) ||
        system_fallback(font, codepoints, languages, opts)

    case fallback do
      {typeface, source} ->
        result
        |> put_resolutions(entries, typeface, source)
        |> put_group_warning(entries, %{
          code: :font_substituted,
          requested: request(font),
          resolved: %{family: typeface.family, source: source}
        })

      nil ->
        unresolved_font(result, entries, font, codepoints, requested)
    end
  end

  defp requested_typeface(%Font{family: nil}), do: {:error, :font_family_missing}

  defp requested_typeface(font),
    do: Skia.Typeface.match_family(font.family, weight: font.weight, slant: font.slant)

  defp usable_typeface({:ok, typeface}, codepoints) do
    case covers?(typeface, codepoints) do
      {:ok, true} -> {:ok, typeface}
      {:ok, false} -> {:missing, typeface}
      {:error, reason} -> {:error, reason}
    end
  end

  defp usable_typeface({:error, _reason}, _codepoints), do: {:missing, nil}

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

  defp unresolved_font(result, entries, font, _codepoints, nil) do
    code = if font.family, do: :font_unavailable, else: :font_family_missing
    put_group_warning(result, entries, %{code: code, requested: request(font)})
  end

  defp unresolved_font(result, entries, font, codepoints, typeface) do
    missing = missing_codepoints(typeface, codepoints)

    result
    |> put_resolutions(entries, typeface, :requested)
    |> put_group_warning(entries, %{
      code: :glyphs_missing,
      characters: missing,
      codepoints: Enum.map(missing, &codepoint_name/1),
      requested: request(font)
    })
  end

  defp covers?(_typeface, []), do: {:ok, true}

  defp covers?(typeface, codepoints) do
    case glyph_ids(typeface, codepoints) do
      {:ok, glyph_ids} -> {:ok, Enum.all?(glyph_ids, &(&1 > 0))}
      {:error, reason} -> {:error, reason}
    end
  end

  defp missing_codepoints(typeface, codepoints) do
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

  defp glyph_ids(typeface, codepoints),
    do: typeface |> Skia.Font.new(size: 14) |> Skia.Font.glyph_ids(Enum.join(codepoints))

  defp put_resolutions(result, entries, typeface, source) do
    fonts =
      Enum.reduce(entries, result.fonts, fn entry, resolved ->
        font = Skia.Font.new(typeface, size: entry.run.font.size || 14)

        Map.put(resolved, font_key(entry), %Resolved{
          font: font,
          family: typeface.family,
          source: source
        })
      end)

    %{result | fonts: fonts}
  end

  defp put_group_warning(result, entries, warning) do
    warnings =
      Enum.reduce(entries, result.warnings, fn entry, diagnosed ->
        run_warning = Map.put(warning, :run, run_metadata(entry.run))
        Map.update(diagnosed, entry.node.guid, [run_warning], &[run_warning | &1])
      end)

    %{result | warnings: warnings}
  end

  defp font_key(entry), do: {entry.node.guid, entry.run.index}

  defp run_metadata(%Run{} = run),
    do: %{index: run.index, start: run.start, length: run.length}

  defp supplied_typefaces(opts) do
    typefaces = Keyword.get(opts, :fallback_typefaces, [])
    paths = Keyword.get(opts, :fallback_font_paths, [])

    cond do
      not is_list(typefaces) or not Enum.all?(typefaces, &is_struct(&1, Skia.Typeface)) ->
        {:error, :invalid_fallback_typefaces}

      not is_list(paths) or not Enum.all?(paths, &is_binary/1) ->
        {:error, :invalid_fallback_font_paths}

      true ->
        load_typeface_paths(paths, typefaces)
    end
  end

  defp load_typeface_paths(paths, typefaces) do
    case Enum.reduce_while(paths, {:ok, []}, &load_typeface_path/2) do
      {:ok, loaded_paths} -> {:ok, typefaces ++ Enum.reverse(loaded_paths)}
      error -> error
    end
  end

  defp load_typeface_path(path, {:ok, loaded}) do
    case Skia.Typeface.load_path(path) do
      {:ok, typeface} -> {:cont, {:ok, [typeface | loaded]}}
      {:error, reason} -> {:halt, {:error, {:fallback_font_load_failed, path, reason}}}
    end
  end

  defp languages(opts) do
    case Keyword.get(opts, :font_languages, []) do
      languages when is_list(languages) ->
        if Enum.all?(languages, &is_binary/1),
          do: {:ok, languages},
          else: {:error, :invalid_font_languages}

      _invalid ->
        {:error, :invalid_font_languages}
    end
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
    |> Enum.uniq()
  end

  defp ignorable_codepoint?(codepoint) do
    <<value::utf8>> = codepoint

    String.trim(codepoint) == "" or value <= 0x1F or value in 0x7F..0x9F or
      value in [0x200C, 0x200D] or value in 0xFE00..0xFE0F or value in 0xE0100..0xE01EF
  end

  defp codepoint_name(<<value::utf8>>) do
    "U+" <> (value |> Integer.to_string(16) |> String.pad_leading(4, "0"))
  end
end
