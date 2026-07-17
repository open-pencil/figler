defmodule Figler.Scene.Graph.Build.StackLayout do
  @moduledoc """
  Applies a small effective auto-layout pass for resolved graph nodes.

  This pass is intentionally conservative. It only relayouts horizontal stacks
  with explicit left padding when visibility/text changes imply Figma collapses
  hidden accessories or repositions visible children.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Graph.Patch

  @doc """
  Applies stack layout adjustments to all graph nodes.
  """
  @spec apply(Graph.t()) :: Graph.t()
  def apply(%Graph{} = graph) do
    Enum.reduce(graph.seed_nodes, graph, fn {parent_guid, parent}, acc ->
      layout_node(acc, parent_guid, parent)
    end)
  end

  defp layout_node(graph, parent_guid, parent) do
    effective_parent = Map.get(graph.nodes, parent_guid)

    if horizontal_stack?(parent) and stack_left_padding(parent) != 0 and
         relayout_stack?(graph, parent_guid, parent, effective_parent) do
      graph
      |> hide_overflowing_stack_accessories(parent_guid, parent, effective_parent)
      |> position_horizontal_stack(parent_guid, parent)
    else
      graph
    end
  end

  defp horizontal_stack?(%{stack_mode: mode}), do: mode in [:horizontal, "horizontal"]
  defp horizontal_stack?(_node), do: false

  defp relayout_stack?(graph, parent_guid, parent, effective_parent) do
    children = stack_children(graph, parent_guid)

    Enum.any?(children, &(&1.visible == false)) or
      tight_text_stack?(children, parent, effective_parent)
  end

  defp tight_text_stack?(children, parent, effective_parent) do
    visible_text = Enum.filter(children, &(&1.visible != false and &1.node_type == "text"))

    match?([_text], visible_text) and
      close?(node_width(hd(visible_text)), stack_inner_width(parent, effective_parent))
  end

  defp hide_overflowing_stack_accessories(graph, parent_guid, parent, effective_parent) do
    children = stack_children(graph, parent_guid)
    text_children = Enum.filter(children, &(&1.node_type == "text" and &1.visible != false))

    case {children, text_children, stack_inner_width(parent, effective_parent)} do
      {children, [text], width} when is_number(width) ->
        if close?(node_width(text), width) and stack_width(children) > width do
          hide_non_text_children(graph, children)
        else
          graph
        end

      _other ->
        graph
    end
  end

  defp hide_non_text_children(graph, children) do
    Enum.reduce(children, graph, fn
      %{node_type: "text"}, acc ->
        acc

      %{guid: guid}, acc ->
        Patch.apply_all(acc, Patch.set(GUID.parse!(guid), :visible, false, source: :stack_layout))
    end)
  end

  defp position_horizontal_stack(graph, parent_guid, parent) do
    {graph, _cursor} =
      graph
      |> stack_children(parent_guid)
      |> Enum.filter(&(&1.visible != false))
      |> Enum.reduce({graph, stack_left_padding(parent)}, &position_stack_child(&2, &1, parent))

    graph
  end

  defp position_stack_child({graph, cursor}, child, parent) do
    transform = Map.put(child.transform || %{}, :m02, cursor)

    graph =
      Patch.apply_all(
        graph,
        Patch.set(GUID.parse!(child.guid), :transform, transform, source: :stack_layout)
      )

    {graph, cursor + node_width(child) + stack_spacing(parent)}
  end

  defp stack_children(graph, parent_guid) do
    graph.children
    |> Map.get(parent_guid, [])
    |> Enum.map(&Map.get(graph.nodes, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp stack_width(children) do
    children
    |> Enum.filter(&(&1.visible != false))
    |> Enum.reduce(0.0, fn child, sum -> sum + node_width(child) end)
  end

  defp stack_inner_width(parent, effective_parent) do
    with %{x: width} <- effective_parent.size do
      width - stack_left_padding(parent) - stack_right_padding(parent)
    end
  end

  defp stack_left_padding(parent), do: parent.stack_horizontal_padding || 0.0

  defp stack_right_padding(parent),
    do: parent.stack_padding_right || parent.stack_horizontal_padding || 0.0

  defp stack_spacing(parent), do: parent.stack_spacing || 0.0
  defp node_width(%{size: %{x: width}}) when is_number(width), do: width
  defp node_width(_node), do: 0.0
  defp close?(left, right), do: abs(left - right) < 0.01
end
