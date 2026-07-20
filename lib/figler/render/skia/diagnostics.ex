defmodule Figler.Render.Skia.Diagnostics do
  @moduledoc false

  alias Figler.Render.Node
  alias Figler.Render.Skia.Effects
  alias Figler.Render.Skia.Paint
  alias Figler.Render.Skia.Shape
  alias Figler.Render.Stroke
  alias Figler.Render.Text
  alias Figler.Render.Text.Case, as: TextCase
  alias Figler.Render.Warning
  alias Figler.Scene.Graph.GUID

  @spec collect(Figler.Render.Scene.t(), [tuple()], map()) :: [Warning.t()]
  def collect(scene, guids, assets) do
    guids
    |> Enum.reduce([], &node_warnings(scene, assets, &1, &2))
    |> Enum.reverse()
    |> Enum.uniq()
  end

  defp node_warnings(scene, assets, guid, warnings) do
    case Map.get(scene.render_nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        warnings = prepend_node_warnings(warnings, node, assets)

        scene.children
        |> Map.get(guid, [])
        |> Enum.reduce(warnings, &node_warnings(scene, assets, &1, &2))

      _missing_or_hidden ->
        warnings
    end
  end

  defp prepend_node_warnings(warnings, node, assets) do
    node_warnings =
      paint_warnings(node.guid, :fill, node.fill_paints || [], node, assets) ++
        paint_warnings(node.guid, :stroke, node.stroke_paints || [], node, assets) ++
        stroke_warnings(node) ++
        boolean_warnings(node) ++
        geometry_warnings(node, assets) ++
        font_warnings(node, assets) ++
        text_warnings(node) ++
        effect_warnings(node) ++
        mask_warnings(node) ++ clip_warnings(node) ++ shape_warnings(node)

    Enum.reduce(node_warnings, warnings, &[&1 | &2])
  end

  defp paint_warnings(guid, kind, paints, node, assets) do
    Enum.flat_map(paints, &paint_warning(&1, guid, kind, node, assets))
  end

  defp paint_warning(%{visible: false}, _guid, _kind, _node, _assets), do: []

  defp paint_warning(
         %{type: paint_type},
         guid,
         :stroke,
         %Node{node_type: node_type},
         _assets
       )
       when node_type not in [:vector, :boolean_operation] and paint_type != :solid,
       do: [
         warning(guid, :stroke, %{code: :non_solid_stroke_unsupported, paint_type: paint_type})
       ]

  defp paint_warning(paint, guid, kind, node, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        Enum.map(resolved.warnings, &warning(guid, kind, &1))

      {:error, :missing_image_asset} ->
        reason = Map.get(assets.errors, Paint.image_key(paint), :missing_image_asset)
        [warning(guid, kind, paint_error(paint, reason))]

      {:error, reason} ->
        [warning(guid, kind, paint_error(paint, reason))]
    end
  end

  defp paint_error(paint, reason) when is_atom(reason),
    do: %{code: reason, paint_type: Map.get(paint, :type)}

  defp paint_error(paint, reason) when is_tuple(reason) and tuple_size(reason) > 0 do
    %{
      code: elem(reason, 0),
      details: reason |> Tuple.to_list() |> tl(),
      paint_type: Map.get(paint, :type)
    }
  end

  defp paint_error(paint, reason),
    do: %{code: :paint_invalid, paint_type: Map.get(paint, :type), reason: reason}

  defp stroke_warnings(%Node{stroke_paints: paints} = node) do
    if Enum.any?(paints || [], &(Map.get(&1, :visible) != false)) do
      node
      |> stroke_warning_values()
      |> Enum.map(&warning(node.guid, :stroke, &1))
    else
      []
    end
  end

  defp stroke_warning_values(%Node{stroke: nil}), do: []

  defp stroke_warning_values(%Node{stroke: stroke} = node) do
    unsupported_alignment? =
      stroke.align not in [nil, :center] and
        (stroke.align not in [:inside, :outside] or not Shape.stroke_alignment_supported?(node))

    []
    |> add_stroke_warning(
      unsupported_alignment?,
      {:stroke_align_approximated, stroke.align}
    )
    |> add_stroke_warning(
      not Stroke.supported_cap?(stroke),
      {:stroke_cap_unsupported, stroke.cap}
    )
    |> add_stroke_warning(not is_nil(stroke.cap_size), :stroke_cap_size_unsupported)
    |> add_stroke_warning(
      not Stroke.valid_dash_pattern?(stroke),
      {:dash_pattern_invalid, stroke.dash_pattern}
    )
    |> add_stroke_warning(
      is_number(stroke.miter_limit) and stroke.miter_limit <= 0,
      {:stroke_miter_invalid, stroke.miter_limit}
    )
  end

  defp add_stroke_warning(warnings, true, value), do: [value | warnings]
  defp add_stroke_warning(warnings, false, _value), do: warnings

  defp font_warnings(node, assets) do
    assets.font_warnings
    |> Map.get(node.guid, [])
    |> Enum.map(&warning(node.guid, :font, &1))
  end

  defp text_warnings(%Node{node_type: :text, text: %Text{} = text} = node) do
    issue_warnings = Enum.map(text.issues, &warning(node.guid, :text, &1))

    issue_warnings ++ Enum.flat_map(text.runs, &text_run_warnings(node.guid, &1))
  end

  defp text_warnings(_node), do: []

  defp text_run_warnings(guid, run) do
    range = %{index: run.index, start: run.start, length: run.length}

    warnings =
      if TextCase.supported?(run.text_case),
        do: [],
        else: [%{code: :text_case_unsupported, value: run.text_case, run: range}]

    warnings =
      if run.fill_override? and Enum.any?(run.fill_paints, &unsupported_text_paint?/1),
        do: [%{code: :text_run_paint_unsupported, run: range} | warnings],
        else: warnings

    warnings =
      if Enum.any?(run.text_decoration_fill_paints, &unsupported_text_paint?/1),
        do: [%{code: :text_decoration_paint_unsupported, run: range} | warnings],
        else: warnings

    warnings =
      if run.text_decoration_thickness,
        do: [%{code: :text_decoration_thickness_unsupported, run: range} | warnings],
        else: warnings

    warnings =
      if run.text_underline_offset,
        do: [%{code: :text_underline_offset_unsupported, run: range} | warnings],
        else: warnings

    Enum.map(warnings, &warning(guid, :text, &1))
  end

  defp unsupported_text_paint?(paint),
    do: paint.visible in [nil, true] and paint.type not in [:solid]

  defp shape_warnings(%Node{node_type: type} = node) do
    issues = Shape.issues(node)

    cond do
      issues != [] ->
        Enum.map(issues, &warning(node.guid, :shape, &1))

      not Shape.visible_paints?(node) ->
        []

      not Shape.supported_type?(type) ->
        [warning(node.guid, :shape, {:shape_unsupported, type})]

      true ->
        []
    end
  end

  defp clip_warnings(%Node{frame_mask_disabled: false, node_type: type} = node) do
    if Node.clipping_container_type?(type),
      do: [],
      else: [warning(node.guid, :shape, {:container_clip_unsupported, type})]
  end

  defp clip_warnings(_node), do: []

  defp mask_warnings(%Node{mask: true, mask_type: :outline} = node),
    do: [warning(node.guid, :mask, :outline_mask_approximated)]

  defp mask_warnings(%Node{mask: true, mask_type: type} = node)
       when type not in [nil, :alpha, :luminance],
       do: [warning(node.guid, :mask, {:mask_type_unsupported, type})]

  defp mask_warnings(_node), do: []

  defp effect_warnings(node) do
    node
    |> Effects.resolve(node.opacity)
    |> Map.fetch!(:warnings)
    |> Enum.map(&warning(node.guid, :effect, &1))
  end

  defp boolean_warnings(%Node{node_type: :boolean_operation} = node) do
    if flattened_boolean_geometry?(node) do
      []
    else
      [
        warning(node.guid, :shape, %{
          code: :live_boolean_geometry_unresolved,
          operation: node.boolean_operation
        })
      ]
    end
  end

  defp boolean_warnings(_node), do: []

  defp geometry_warnings(%Node{node_type: :boolean_operation} = node, assets) do
    if flattened_boolean_geometry?(node), do: geometry_warnings_for_node(node, assets), else: []
  end

  defp geometry_warnings(%Node{node_type: :vector} = node, assets),
    do: geometry_warnings_for_node(node, assets)

  defp geometry_warnings(_node, _assets), do: []

  defp geometry_warnings_for_node(node, assets) do
    []
    |> geometry_warning(node, assets, :fill, node.fill_paints || [])
    |> geometry_warning(node, assets, :stroke, node.stroke_paints || [])
  end

  defp flattened_boolean_geometry?(node) do
    not is_nil(node.vector_network) or node.fill_geometry != [] or node.stroke_geometry != []
  end

  defp geometry_warning(warnings, node, assets, kind, paints) do
    if Enum.any?(paints, &(Map.get(&1, :visible) != false)) do
      case Map.get(assets.vector_network_errors, node.guid) do
        nil -> geometry_reference_warning(warnings, node, assets, kind)
        reason -> [warning(node.guid, kind, {:invalid_vector_network, reason}) | warnings]
      end
    else
      warnings
    end
  end

  defp geometry_reference_warning(warnings, node, assets, kind) do
    case get_in(assets, [Access.key(:geometry_errors), node.guid, kind]) do
      nil -> missing_geometry_warning(warnings, node, kind)
      reason -> [warning(node.guid, kind, {:invalid_geometry, reason}) | warnings]
    end
  end

  defp missing_geometry_warning(warnings, %{vector_network: reference}, _kind)
       when not is_nil(reference),
       do: warnings

  defp missing_geometry_warning(warnings, node, kind) do
    if geometry_references(node, kind) == [] do
      [warning(node.guid, kind, :geometry_missing) | warnings]
    else
      warnings
    end
  end

  defp geometry_references(node, :fill), do: node.fill_geometry || []
  defp geometry_references(node, :stroke), do: node.stroke_geometry || []

  defp warning(guid, kind, value),
    do: Warning.new(GUID.format(guid), kind, value)
end
