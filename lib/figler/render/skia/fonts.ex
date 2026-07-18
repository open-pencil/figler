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

  defmodule Span do
    @moduledoc false

    @enforce_keys [:index, :source_index, :start, :length, :content, :font]
    defstruct [
      :index,
      :source_index,
      :start,
      :length,
      :content,
      :font,
      :style_id,
      :text_decoration,
      :resolved,
      fill_paints: [],
      fill_override?: false
    ]

    @type t :: %__MODULE__{
            index: non_neg_integer(),
            source_index: non_neg_integer(),
            start: non_neg_integer(),
            length: non_neg_integer(),
            content: String.t(),
            font: Font.t(),
            style_id: non_neg_integer(),
            text_decoration: atom() | nil,
            resolved: Resolved.t() | nil,
            fill_paints: [Figler.Render.Paint.t()],
            fill_override?: boolean()
          }
  end

  @type font_key :: {tuple(), non_neg_integer(), non_neg_integer()}
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
          spans: %{optional(tuple()) => [Span.t()]},
          warnings: %{optional(tuple()) => [warning_value()]}
        }

  @spec resolve([Node.t()], keyword()) :: {:ok, result()} | {:error, term()}
  def resolve(nodes, opts) do
    with {:ok, supplied} <- supplied_typefaces(opts),
         {:ok, languages} <- languages(opts) do
      entries = text_entries(nodes, supplied)
      groups = Enum.group_by(entries, &resolution_key/1)

      result =
        Enum.reduce(groups, %{fonts: %{}, spans: %{}, warnings: %{}}, fn {_key, group},
                                                                         resolved ->
          resolve_group(group, supplied, languages, opts, resolved)
        end)

      {:ok, result |> put_spans(entries) |> sort_warnings()}
    end
  end

  defp sort_warnings(result) do
    warnings =
      Map.new(result.warnings, fn {guid, values} ->
        values = values |> Enum.sort_by(&{&1.run.start, &1.run.index}) |> merge_warnings()
        {guid, values}
      end)

    %{result | warnings: warnings}
  end

  defp text_entries(nodes, supplied) do
    Enum.flat_map(nodes, fn
      %Node{node_type: :text, text: %Text{} = text} = node ->
        Enum.flat_map(text.runs, &run_entries(node, text, &1, supplied))

      _node ->
        []
    end)
  end

  defp run_entries(_node, _text, %Run{content: ""}, _supplied), do: []

  defp run_entries(node, text, run, supplied) do
    case prepare_requested_run(run, supplied) do
      {:resolved, resolved} ->
        [
          %{
            node: node,
            text: text,
            run: run,
            cluster_index: 0,
            pre_resolved: resolved,
            requested: nil
          }
        ]

      {:split, requested} ->
        grapheme_entries(node, text, run, requested)
    end
  end

  defp prepare_requested_run(run, supplied) do
    codepoints = codepoints(run.content)

    case requested_supplied_typeface(supplied, run.font, codepoints) do
      nil -> prepare_system_requested_run(run.font, codepoints)
      typeface -> {:resolved, {typeface, :supplied}}
    end
  end

  defp prepare_system_requested_run(font, codepoints) do
    requested = requested_typeface(font)

    case usable_typeface(requested, codepoints) do
      {:ok, typeface} -> {:resolved, {typeface, :requested}}
      _unresolved -> {:split, requested}
    end
  end

  defp grapheme_entries(node, text, run, requested) do
    {entries, _offset} =
      run.content
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map_reduce(run.start, fn {content, cluster_index}, start ->
        length = utf16_length(content)
        entry_run = %{run | start: start, length: length, content: content}

        entry = %{
          node: node,
          text: text,
          run: entry_run,
          cluster_index: cluster_index,
          pre_resolved: nil,
          requested: requested
        }

        {entry, start + length}
      end)

    entries
  end

  defp resolution_key(%{text: text, run: run} = entry) do
    font = run.font

    {
      pre_resolved_signature(entry.pre_resolved),
      font.family,
      font.style,
      font.postscript,
      font.weight,
      font.slant,
      codepoints(run.content),
      Enum.map(text.fallback_fonts, &{&1.family, &1.weight, &1.slant})
    }
  end

  defp pre_resolved_signature(nil), do: nil
  defp pre_resolved_signature({typeface, source}), do: {typeface.family, source}

  defp resolve_group([representative | _] = entries, supplied, languages, opts, result) do
    case representative.pre_resolved do
      {typeface, source} ->
        put_resolutions(result, entries, typeface, source)

      nil ->
        resolve_unprepared_group(entries, representative, supplied, languages, opts, result)
    end
  end

  defp resolve_unprepared_group(entries, representative, supplied, languages, opts, result) do
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
    case usable_typeface(representative.requested, codepoints) do
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
      entries
      |> Enum.reject(&(codepoints(&1.run.content) == []))
      |> Enum.reduce(result.warnings, fn entry, diagnosed ->
        run_warning = Map.put(warning, :run, run_metadata(entry.run))
        Map.update(diagnosed, entry.node.guid, [run_warning], &[run_warning | &1])
      end)

    %{result | warnings: warnings}
  end

  defp font_key(entry), do: {entry.node.guid, entry.run.index, entry.cluster_index}

  defp run_metadata(%Run{} = run),
    do: %{index: run.index, start: run.start, length: run.length}

  defp put_spans(result, entries) do
    spans =
      entries
      |> Enum.group_by(& &1.node.guid)
      |> Map.new(fn {guid, node_entries} ->
        spans =
          node_entries
          |> Enum.map(&entry_span(&1, Map.get(result.fonts, font_key(&1))))
          |> merge_spans()
          |> Enum.with_index()
          |> Enum.map(fn {span, index} -> %{span | index: index} end)

        {guid, spans}
      end)

    %{result | spans: spans}
  end

  defp entry_span(entry, resolved) do
    run = entry.run

    %Span{
      index: 0,
      source_index: run.index,
      start: run.start,
      length: run.length,
      content: run.content,
      font: run.font,
      style_id: run.style_id,
      text_decoration: run.text_decoration,
      resolved: resolved,
      fill_paints: run.fill_paints,
      fill_override?: run.fill_override?
    }
  end

  defp merge_spans(spans) do
    spans
    |> Enum.reduce([], fn span, merged -> merge_span(span, merged) end)
    |> Enum.reverse()
  end

  defp merge_span(span, [previous | rest]) do
    if mergeable_span?(previous, span) do
      merged = %{
        previous
        | length: previous.length + span.length,
          content: previous.content <> span.content
      }

      [merged | rest]
    else
      [span, previous | rest]
    end
  end

  defp merge_span(span, []), do: [span]

  defp mergeable_span?(left, right) do
    left.source_index == right.source_index and
      left.start + left.length == right.start and
      resolved_signature(left.resolved) == resolved_signature(right.resolved)
  end

  defp resolved_signature(nil), do: nil
  defp resolved_signature(resolved), do: {resolved.source, resolved.family}

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

  defp utf16_length(content) do
    Enum.reduce(String.codepoints(content), 0, fn codepoint, length ->
      <<value::utf8>> = codepoint
      length + if(value > 0xFFFF, do: 2, else: 1)
    end)
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
