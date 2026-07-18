defmodule Figler.Render.Skia.Fonts do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.Font, Skia.Typeface]}

  alias Figler.Render.Font
  alias Figler.Render.Node
  alias Figler.Render.Text

  defmodule Resolved do
    @moduledoc false

    defstruct [:font, :family, :source]

    @type t :: %__MODULE__{
            font: Skia.Font.t(),
            family: String.t() | nil,
            source: :requested | :supplied | :system
          }
  end

  @type warning_value :: %{
          required(:code) =>
            :font_family_missing
            | :font_unavailable
            | :font_inspection_failed
            | :font_substituted
            | :glyphs_missing,
          optional(atom()) => term()
        }

  @type result :: %{
          fonts: %{optional(tuple()) => Resolved.t()},
          warnings: %{optional(tuple()) => [warning_value()]}
        }

  @spec resolve([Node.t()], keyword()) :: {:ok, result()} | {:error, term()}
  def resolve(nodes, opts) do
    with {:ok, supplied} <- supplied_typefaces(opts),
         {:ok, languages} <- languages(opts) do
      text_nodes = Enum.filter(nodes, &text_node?/1)
      groups = Enum.group_by(text_nodes, &resolution_key/1)

      result =
        Enum.reduce(groups, %{fonts: %{}, warnings: %{}}, fn {_key, group}, resolved ->
          resolve_group(group, supplied, languages, opts, resolved)
        end)

      {:ok, result}
    end
  end

  defp text_node?(%Node{node_type: :text, text: %Text{content: content}}),
    do: content != ""

  defp text_node?(_node), do: false

  defp resolution_key(%Node{text: %Text{font: font, content: content}}),
    do: {font.family, font.style, font.postscript, font.weight, font.slant, codepoints(content)}

  defp resolve_group([representative | _] = nodes, supplied, languages, opts, result) do
    font = representative.text.font
    codepoints = codepoints(representative.text.content)
    requested = requested_typeface(font)

    case usable_typeface(requested, codepoints) do
      {:ok, typeface} ->
        put_resolutions(result, nodes, typeface, :requested)

      {:missing, requested_typeface} ->
        resolve_fallback(
          result,
          nodes,
          font,
          codepoints,
          requested_typeface,
          supplied,
          languages,
          opts
        )

      {:error, reason} ->
        put_group_warning(result, nodes, %{
          code: :font_inspection_failed,
          reason: reason,
          requested: request(font)
        })
    end
  end

  defp resolve_fallback(result, nodes, font, codepoints, requested, supplied, languages, opts) do
    fallback =
      supplied_fallback(supplied, codepoints) ||
        system_fallback(font, codepoints, languages, opts)

    case fallback do
      {typeface, source} ->
        result
        |> put_resolutions(nodes, typeface, source)
        |> put_group_warning(nodes, %{
          code: :font_substituted,
          requested: request(font),
          resolved: %{family: typeface.family, source: source}
        })

      nil ->
        unresolved_font(result, nodes, font, codepoints, requested)
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

  defp unresolved_font(result, nodes, font, _codepoints, nil) do
    code = if font.family, do: :font_unavailable, else: :font_family_missing
    put_group_warning(result, nodes, %{code: code, requested: request(font)})
  end

  defp unresolved_font(result, nodes, font, codepoints, typeface) do
    missing = missing_codepoints(typeface, codepoints)

    result
    |> put_resolutions(nodes, typeface, :requested)
    |> put_group_warning(nodes, %{
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

  defp put_resolutions(result, nodes, typeface, source) do
    fonts =
      Enum.reduce(nodes, result.fonts, fn node, resolved ->
        font = Skia.Font.new(typeface, size: node.text.font.size || 14)

        Map.put(resolved, node.guid, %Resolved{
          font: font,
          family: typeface.family,
          source: source
        })
      end)

    %{result | fonts: fonts}
  end

  defp put_group_warning(result, nodes, warning) do
    warnings =
      Enum.reduce(nodes, result.warnings, fn node, diagnosed ->
        Map.update(diagnosed, node.guid, [warning], &[warning | &1])
      end)

    %{result | warnings: warnings}
  end

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
