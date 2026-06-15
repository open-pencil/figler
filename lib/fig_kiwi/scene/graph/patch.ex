defmodule FigKiwi.Scene.Graph.Patch do
  @moduledoc """
  Data-first graph patch operations.

  Resolver stages emit patches instead of mutating node fields directly. Keeping
  patches as ordinary structs makes graph changes easy to test, diff, and record
  in provenance before any Figma-specific rule language exists.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Swap

  @enforce_keys [:op, :target, :source]
  defstruct [:op, :target, :field, :value, :source, meta: %{}]

  @type t :: %__MODULE__{
          op: :set | :swap,
          target: GUID.graph_guid(),
          field: atom() | nil,
          value: term(),
          source: atom(),
          meta: map()
        }

  @doc """
  Creates a field assignment patch.
  """
  @spec set(GUID.graph_guid(), atom(), term(), keyword()) :: t()
  def set(target, field, value, opts \\ []) when is_tuple(target) and is_atom(field) do
    %__MODULE__{
      op: :set,
      target: target,
      field: field,
      value: value,
      source: Keyword.fetch!(opts, :source),
      meta: Keyword.get(opts, :meta, %{})
    }
  end

  @doc """
  Creates a component swap intent patch.
  """
  @spec swap(GUID.graph_guid(), GUID.figma_guid(), keyword()) :: t()
  def swap(target, component_guid, opts \\ [])
      when is_tuple(target) and is_tuple(component_guid) do
    %__MODULE__{
      op: :swap,
      target: target,
      field: :component_guid,
      value: component_guid,
      source: Keyword.fetch!(opts, :source),
      meta: Keyword.get(opts, :meta, %{})
    }
  end

  @doc """
  Applies one or more patches to a graph.
  """
  @spec apply_all(Graph.t(), t() | [t()]) :: Graph.t()
  def apply_all(%Graph{} = graph, %__MODULE__{} = patch), do: apply_all(graph, [patch])

  def apply_all(%Graph{} = graph, patches) when is_list(patches) do
    Enum.reduce(patches, graph, &apply_one/2)
  end

  defp apply_one(%__MODULE__{op: :set} = patch, %Graph{} = graph) do
    case Map.fetch(graph.nodes, patch.target) do
      :error ->
        %Graph{
          graph
          | unresolved: [{:patch_target, patch.target, patch.source} | graph.unresolved]
        }

      {:ok, node} ->
        old_value = Map.get(node, patch.field)
        patched = Map.put(node, patch.field, patch.value)
        applied = {patch.source, patch.field, old_value, patch.value}

        %Graph{
          graph
          | nodes: Map.put(graph.nodes, patch.target, patched),
            provenance:
              Map.update(
                graph.provenance,
                patch.target,
                provenance(applied),
                &append_applied(&1, applied)
              )
        }
    end
  end

  defp apply_one(%__MODULE__{op: :swap} = patch, %Graph{} = graph) do
    case Map.fetch(graph.nodes, patch.target) do
      {:ok, %{node_type: "instance"}} ->
        if Map.has_key?(graph.nodes, patch.value) do
          old_value = graph.seed_nodes |> Map.get(patch.target) |> old_component()
          applied = {patch.source, :component_guid, old_value, patch.value}

          graph
          |> put_swap(patch, applied)
          |> Swap.run(patch.target, patch.value)
        else
          %Graph{
            graph
            | unresolved: [
                {:swap_component, patch.target, patch.value, :missing} | graph.unresolved
              ]
          }
        end

      {:ok, _node} ->
        %Graph{
          graph
          | unresolved: [{:swap_target, patch.target, :not_instance} | graph.unresolved]
        }

      :error ->
        %Graph{graph | unresolved: [{:swap_target, patch.target, :missing} | graph.unresolved]}
    end
  end

  defp put_swap(%Graph{} = graph, patch, applied) do
    %Graph{
      graph
      | seed_nodes: update_seed(graph.seed_nodes, patch.target, patch.value),
        provenance:
          Map.update(
            graph.provenance,
            patch.target,
            provenance(applied),
            &append_applied(&1, applied)
          )
    }
  end

  defp old_component(nil), do: nil
  defp old_component(seed), do: seed.symbol_id

  defp update_seed(seed_nodes, target, component_guid) do
    Map.update(seed_nodes, target, nil, fn
      nil -> nil
      seed -> %{seed | symbol_id: component_guid, component_guid: component_guid}
    end)
  end

  defp provenance(applied), do: %{applied: [applied]}

  defp append_applied(provenance, applied) do
    Map.update(provenance, :applied, [applied], &[applied | &1])
  end
end
