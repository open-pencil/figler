defmodule FigKiwi.Scene.Graph.Focus do
  @moduledoc false

  alias FigKiwi.Scene.Graph.SeedNode

  @doc false
  def materialize(seed_nodes, options) do
    case Keyword.get(options, :focus) do
      nil -> seed_nodes
      [] -> seed_nodes
      focus -> focused_seed_nodes(seed_nodes, focus)
    end
  end

  defp focused_seed_nodes(seed_nodes, focus) do
    seed_by_guid = Map.new(seed_nodes, &{&1.guid, &1})
    children = build_children(seed_nodes)

    focused_guids =
      focus
      |> Enum.reduce(MapSet.new(), &collect_subtree(&2, &1, seed_by_guid, children))
      |> collect_instance_components(seed_by_guid, children)
      |> collect_ancestors(seed_by_guid)

    Enum.filter(seed_nodes, &MapSet.member?(focused_guids, &1.guid))
  end

  defp collect_instance_components(guids, seed_by_guid, children) do
    next =
      Enum.reduce(guids, guids, fn guid, acc ->
        case Map.get(seed_by_guid, guid) do
          %SeedNode{node_type: "instance"} = seed ->
            seed
            |> referenced_components()
            |> Enum.reduce(acc, &collect_subtree(&2, &1, seed_by_guid, children))

          _seed ->
            acc
        end
      end)

    if MapSet.size(next) == MapSet.size(guids) do
      next
    else
      collect_instance_components(next, seed_by_guid, children)
    end
  end

  defp referenced_components(seed) do
    symbol_ids = if is_tuple(seed.symbol_id), do: [seed.symbol_id], else: []

    swap_ids =
      seed.symbol_overrides
      |> Enum.flat_map(fn override ->
        assignment_ids =
          override.component_prop_assignments
          |> Enum.map(&component_assignment_guid/1)
          |> Enum.filter(&is_tuple/1)

        [override.overridden_symbol_id | assignment_ids]
      end)
      |> Enum.filter(&is_tuple/1)

    assignment_ids =
      seed.component_prop_assignments
      |> Enum.map(&component_assignment_guid/1)
      |> Enum.filter(&is_tuple/1)

    symbol_ids ++ swap_ids ++ assignment_ids
  end

  defp component_assignment_guid(%{value: {:guid, guid}}), do: guid
  defp component_assignment_guid(_assignment), do: nil

  defp collect_ancestors(guids, seed_by_guid) do
    Enum.reduce(guids, guids, &collect_ancestor(&2, &1, seed_by_guid))
  end

  defp collect_ancestor(guids, guid, seed_by_guid) do
    case Map.get(seed_by_guid, guid) do
      %{parent_guid: parent_guid} when is_tuple(parent_guid) ->
        guids
        |> MapSet.put(parent_guid)
        |> collect_ancestor(parent_guid, seed_by_guid)

      _seed ->
        guids
    end
  end

  defp collect_subtree(guids, guid, seed_by_guid, children) do
    if Map.has_key?(seed_by_guid, guid) do
      children
      |> Map.get(guid, [])
      |> Enum.reduce(MapSet.put(guids, guid), &collect_subtree(&2, &1, seed_by_guid, children))
    else
      guids
    end
  end

  defp build_children(seed_nodes) do
    seed_nodes
    |> Enum.reduce(%{}, fn
      %SeedNode{parent_guid: nil}, acc ->
        acc

      %SeedNode{parent_guid: parent_guid, guid: guid}, acc ->
        Map.update(acc, parent_guid, [guid], &[guid | &1])
    end)
  end
end
