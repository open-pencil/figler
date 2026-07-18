defmodule Figler.Render.Skia.Diagnostics do
  @moduledoc false

  alias Figler.Render.Node
  alias Figler.Render.Skia.Effects
  alias Figler.Render.Skia.Paint
  alias Figler.Render.Skia.Shape
  alias Figler.Scene.Graph.GUID

  @spec collect(Figler.Render.Scene.t(), [tuple()], map()) :: [map()]
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
        geometry_warnings(node, assets) ++
        font_warnings(node, assets) ++
        effect_warnings(node) ++ mask_warnings(node) ++ shape_warnings(node)

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

  defp font_warnings(node, assets) do
    assets.font_warnings
    |> Map.get(node.guid, [])
    |> Enum.map(&warning(node.guid, :font, &1))
  end

  defp shape_warnings(%Node{node_type: type} = node) do
    if Shape.supported_type?(type) or not Shape.visible_paints?(node) do
      []
    else
      [warning(node.guid, :shape, {:shape_unsupported, type})]
    end
  end

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

  defp geometry_warnings(%Node{node_type: type} = node, assets)
       when type in [:vector, :boolean_operation] do
    []
    |> geometry_warning(node, assets, :fill, node.fill_paints || [])
    |> geometry_warning(node, assets, :stroke, node.stroke_paints || [])
  end

  defp geometry_warnings(_node, _assets), do: []

  defp geometry_warning(warnings, node, assets, kind, paints) do
    if Enum.any?(paints, &(Map.get(&1, :visible) != false)) do
      case get_in(assets, [Access.key(:geometry_errors), node.guid, kind]) do
        nil -> missing_geometry_warning(warnings, node, kind)
        reason -> [warning(node.guid, kind, {:invalid_geometry, reason}) | warnings]
      end
    else
      warnings
    end
  end

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
    do: %{guid: GUID.format(guid), feature: kind, value: value}
end
