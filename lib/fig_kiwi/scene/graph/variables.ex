defmodule FigKiwi.Scene.Graph.Variables do
  @moduledoc """
  Preserves variable/style references and records unresolved diagnostics.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.SeedNode

  @style_fields [
    :text_style_guid,
    :fill_style_guid,
    :stroke_style_guid,
    :effect_style_guid,
    :grid_style_guid
  ]

  @doc false
  @spec apply(Graph.t()) :: Graph.t()
  def apply(%Graph{} = graph) do
    Enum.reduce(graph.seed_nodes, graph, fn {_guid, seed}, acc ->
      unresolved = unresolved_refs(graph, seed)

      if unresolved == [] do
        acc
      else
        put_unresolved(acc, seed.guid, unresolved)
      end
    end)
  end

  defp unresolved_refs(%Graph{} = graph, %SeedNode{} = seed) do
    variable_refs(graph, seed) ++ style_refs(graph, seed)
  end

  defp variable_refs(%Graph{options: options}, seed) do
    case Keyword.get(options, :resolve_variables, :known) do
      false -> []
      _mode -> variable_refs(seed)
    end
  end

  defp variable_refs(%SeedNode{variable_consumption: []}), do: []

  defp variable_refs(%SeedNode{variable_consumption: refs}) do
    Enum.map(refs, &{:variable_ref_preserved, &1})
  end

  defp style_refs(%Graph{options: options}, seed) do
    case Keyword.get(options, :resolve_styles, false) do
      false -> []
      _mode -> style_refs(seed)
    end
  end

  defp style_refs(seed) do
    @style_fields
    |> Enum.flat_map(fn field ->
      case Map.get(seed, field) do
        nil -> []
        guid -> [{:style_ref_preserved, field, guid}]
      end
    end)
  end

  defp put_unresolved(%Graph{} = graph, guid, unresolved) do
    provenance =
      Map.update(graph.provenance, guid, %{unresolved: unresolved}, fn existing ->
        Map.update(existing, :unresolved, unresolved, &(unresolved ++ &1))
      end)

    %Graph{graph | provenance: provenance, unresolved: unresolved ++ graph.unresolved}
  end
end
