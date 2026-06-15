defmodule FigKiwi.Scene.Graph.Patch do
  @moduledoc """
  Data-first graph patch operations.

  Resolver stages emit patches instead of mutating node fields directly. Keeping
  patches as ordinary structs makes graph changes easy to test, diff, and record
  in provenance before any Figma-specific rule language exists.
  """

  alias FigKiwi.Scene.Graph

  @enforce_keys [:op, :target, :source]
  defstruct [:op, :target, :field, :value, :source, meta: %{}]

  @type t :: %__MODULE__{
          op: :set,
          target: String.t(),
          field: atom() | nil,
          value: term(),
          source: atom(),
          meta: map()
        }

  @doc """
  Creates a field assignment patch.
  """
  @spec set(String.t(), atom(), term(), keyword()) :: t()
  def set(target, field, value, opts \\ []) when is_binary(target) and is_atom(field) do
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

  defp provenance(applied), do: %{applied: [applied]}

  defp append_applied(provenance, applied) do
    Map.update(provenance, :applied, [applied], &[applied | &1])
  end
end
