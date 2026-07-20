defmodule Figler.Render.Skia.Bounds do
  @moduledoc false

  alias Figler.Render.Affine
  alias Figler.Render.Bounds
  alias Figler.Render.Node

  @spec content(Figler.Render.Scene.t(), tuple()) ::
          {:ok, Bounds.t()} | {:error, :empty_render_root}
  def content(scene, root_guid) do
    case for_guids(scene, render_guids(scene, root_guid)) do
      %Bounds{} = bounds -> {:ok, bounds}
      nil -> {:error, :empty_render_root}
    end
  end

  @spec for_guids(Figler.Render.Scene.t(), [tuple()]) :: Bounds.t() | nil
  def for_guids(scene, guids) do
    Enum.reduce(guids, nil, &node_bounds(scene, &1, Affine.identity(), &2))
  end

  @spec shape(Node.t()) :: Bounds.t() | nil
  def shape(node) do
    nil
    |> include_rect(Affine.identity(), node.size)
    |> include_stroke_bounds(Affine.identity(), node.size, node)
    |> include_effect_bounds(Affine.identity(), node.size, node)
  end

  @spec layer_option(Bounds.t() | nil) :: keyword()
  def layer_option(nil), do: []

  def layer_option(%Bounds{} = bounds) do
    [
      bounds:
        {bounds.min_x, bounds.min_y, bounds.max_x - bounds.min_x, bounds.max_y - bounds.min_y}
    ]
  end

  @spec render_guids(Figler.Render.Scene.t(), tuple()) :: [tuple()]
  def render_guids(scene, root_guid) do
    case Map.get(scene.render_nodes, root_guid) do
      %Node{node_type: :canvas} -> Map.get(scene.children, root_guid, [])
      %Node{} -> [root_guid]
      nil -> []
    end
  end

  defp node_bounds(scene, guid, parent_matrix, bounds) do
    case Map.get(scene.render_nodes, guid) do
      %Node{visible: visible, node_type: :boolean_operation} = node when visible != false ->
        matrix = Affine.multiply(parent_matrix, Affine.from_value(node.transform))

        bounds
        |> include_rect(matrix, node.size)
        |> include_stroke_bounds(matrix, node.size, node)
        |> include_effect_bounds(matrix, node.size, node)

      %Node{visible: visible} = node when visible != false ->
        matrix = Affine.multiply(parent_matrix, Affine.from_value(node.transform))

        bounds =
          bounds
          |> include_rect(matrix, node.size)
          |> include_stroke_bounds(matrix, node.size, node)
          |> include_effect_bounds(matrix, node.size, node)

        scene.children
        |> Map.get(guid, [])
        |> Enum.reduce(bounds, &node_bounds(scene, &1, matrix, &2))

      _missing_or_hidden ->
        bounds
    end
  end

  defp include_rect(bounds, _matrix, nil), do: bounds

  defp include_rect(bounds, matrix, %{x: width, y: height})
       when is_number(width) and is_number(height) do
    include_local_rect(bounds, matrix, {0.0, 0.0, width, height})
  end

  defp include_rect(bounds, _matrix, _size), do: bounds

  defp include_local_rect(bounds, matrix, {x, y, width, height}) do
    points = [
      Affine.point(matrix, x, y),
      Affine.point(matrix, x + width, y),
      Affine.point(matrix, x, y + height),
      Affine.point(matrix, x + width, y + height)
    ]

    [first | rest] = points

    point_bounds =
      Enum.reduce(rest, point_bounds(first), fn {px, py}, acc ->
        %Bounds{
          min_x: min(acc.min_x, px),
          min_y: min(acc.min_y, py),
          max_x: max(acc.max_x, px),
          max_y: max(acc.max_y, py)
        }
      end)

    union(bounds, point_bounds)
  end

  defp include_stroke_bounds(bounds, _matrix, nil, _node), do: bounds

  defp include_stroke_bounds(bounds, matrix, %{x: width, y: height}, node) do
    visible? = Enum.any?(node.stroke_paints || [], &(Map.get(&1, :visible) != false))
    stroke = node.stroke

    if visible? and not is_nil(stroke) and is_number(stroke.weight) and stroke.weight > 0 do
      padding = stroke_padding(stroke.align, stroke.weight)

      include_local_rect(
        bounds,
        matrix,
        {-padding, -padding, width + padding * 2, height + padding * 2}
      )
    else
      bounds
    end
  end

  defp stroke_padding(:inside, _weight), do: 0.0
  defp stroke_padding(:outside, weight), do: weight
  defp stroke_padding(_alignment, weight), do: weight / 2

  defp include_effect_bounds(bounds, _matrix, nil, _node), do: bounds

  defp include_effect_bounds(bounds, matrix, %{x: width, y: height}, node) do
    node.effects
    |> Kernel.||([])
    |> Enum.reject(&(Map.get(&1, :visible) == false))
    |> Enum.reduce(bounds, fn effect, expanded ->
      include_effect_bound(expanded, matrix, width, height, effect)
    end)
  end

  defp include_effect_bound(bounds, matrix, width, height, %{type: :drop_shadow} = effect) do
    offset = Map.get(effect, :offset) || %{}
    x = Map.get(offset, :x) || 0.0
    y = Map.get(offset, :y) || 0.0
    padding = max((Map.get(effect, :radius) || 0.0) * 2, abs(Map.get(effect, :spread) || 0.0))
    left = min(0.0, x) - padding
    top = min(0.0, y) - padding
    right = max(width, width + x) + padding
    bottom = max(height, height + y) + padding
    include_local_rect(bounds, matrix, {left, top, right - left, bottom - top})
  end

  defp include_effect_bound(bounds, matrix, width, height, %{type: :foreground_blur} = effect) do
    padding = (Map.get(effect, :radius) || 0.0) * 2

    include_local_rect(
      bounds,
      matrix,
      {-padding, -padding, width + padding * 2, height + padding * 2}
    )
  end

  defp include_effect_bound(bounds, _matrix, _width, _height, _effect), do: bounds

  defp point_bounds({x, y}), do: %Bounds{min_x: x, min_y: y, max_x: x, max_y: y}
  defp union(nil, bounds), do: bounds

  defp union(left, right) do
    %Bounds{
      min_x: min(left.min_x, right.min_x),
      min_y: min(left.min_y, right.min_y),
      max_x: max(left.max_x, right.max_x),
      max_y: max(left.max_y, right.max_y)
    }
  end
end
