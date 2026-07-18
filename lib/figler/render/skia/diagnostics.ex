defmodule Figler.Render.Skia.Diagnostics do
  @moduledoc false

  alias Figler.Render.Skia.Effects
  alias Figler.Render.Skia.Paint
  alias Figler.Render.Skia.Shape
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Node

  @spec collect(Figler.Render.Scene.t(), [tuple()], map()) :: [map()]
  def collect(scene, guids, assets) do
    guids
    |> Enum.reduce([], &node_warnings(scene, assets, &1, &2))
    |> Enum.reverse()
    |> Enum.uniq()
  end

  defp node_warnings(scene, assets, guid, warnings) do
    case Map.get(scene.graph.nodes, guid) do
      %Node{visible: visible} = node when visible != false ->
        source = source_node(scene, guid)
        warnings = prepend_source_warnings(warnings, source, node, guid, assets)

        scene.graph.children
        |> Map.get(guid, [])
        |> Enum.reduce(warnings, &node_warnings(scene, assets, &1, &2))

      _missing_or_hidden ->
        warnings
    end
  end

  defp prepend_source_warnings(warnings, nil, _node, _guid, _assets), do: warnings

  defp prepend_source_warnings(warnings, source, node, guid, assets) do
    source_warnings =
      paint_warnings(guid, :fill, source.fill_paints || [], node, assets) ++
        paint_warnings(guid, :stroke, source.stroke_paints || [], node, assets) ++
        geometry_warnings(guid, node, source, assets) ++
        effect_warnings(guid, node, source) ++
        mask_warnings(guid, source) ++ shape_warnings(guid, node, source)

    Enum.reduce(source_warnings, warnings, &[&1 | &2])
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
       when node_type not in ["vector", "boolean_operation"] and paint_type != :solid,
       do: [warning(guid, :stroke, {paint_type, :non_solid_stroke_unsupported})]

  defp paint_warning(paint, guid, kind, node, assets) do
    case Paint.resolve(paint, node.size, assets.images) do
      {:ok, resolved} ->
        Enum.map(resolved.warnings, &warning(guid, kind, &1))

      {:error, :missing_image_asset} ->
        reason = Map.get(assets.errors, Paint.image_key(paint), :missing_image_asset)
        [warning(guid, kind, reason)]

      {:error, reason} ->
        [warning(guid, kind, {Map.get(paint, :type), reason})]
    end
  end

  defp shape_warnings(guid, %Node{node_type: type}, source) do
    if Shape.supported_type?(type) or not Shape.visible_paints?(source) do
      []
    else
      [warning(guid, :shape, {:shape_unsupported, type})]
    end
  end

  defp mask_warnings(guid, %{mask: true, mask_type: :outline}),
    do: [warning(guid, :mask, :outline_mask_approximated)]

  defp mask_warnings(guid, %{mask: true, mask_type: type})
       when type not in [nil, :alpha, :luminance],
       do: [warning(guid, :mask, {:mask_type_unsupported, type})]

  defp mask_warnings(_guid, _source), do: []

  defp effect_warnings(guid, node, source) do
    source
    |> Effects.resolve(node.opacity)
    |> Map.fetch!(:warnings)
    |> Enum.map(&warning(guid, :effect, &1))
  end

  defp geometry_warnings(guid, %Node{node_type: type}, source, assets)
       when type in ["vector", "boolean_operation"] do
    []
    |> geometry_warning(guid, source, assets, :fill, source.fill_paints || [])
    |> geometry_warning(guid, source, assets, :stroke, source.stroke_paints || [])
  end

  defp geometry_warnings(_guid, _node, _source, _assets), do: []

  defp geometry_warning(warnings, guid, source, assets, kind, paints) do
    if Enum.any?(paints, &(Map.get(&1, :visible) != false)) do
      case get_in(assets, [Access.key(:geometry_errors), source.guid, kind]) do
        nil -> missing_geometry_warning(warnings, guid, source, kind)
        reason -> [warning(guid, kind, {:invalid_geometry, reason}) | warnings]
      end
    else
      warnings
    end
  end

  defp missing_geometry_warning(warnings, guid, source, kind) do
    if geometry_references(source, kind) == [] do
      [warning(guid, kind, :geometry_missing) | warnings]
    else
      warnings
    end
  end

  defp geometry_references(source, :fill), do: source.fill_geometry || []
  defp geometry_references(source, :stroke), do: source.stroke_geometry || []

  defp warning(guid, kind, value),
    do: %{guid: GUID.format(guid), feature: kind, value: value}

  defp source_node(scene, guid), do: Map.get(scene.render_nodes, guid)
end
