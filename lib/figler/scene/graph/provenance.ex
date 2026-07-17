defmodule Figler.Scene.Graph.Provenance do
  @moduledoc """
  Builds and updates provenance metadata for resolved graph nodes.

  Provenance records explain whether a node came directly from the projected
  index or was cloned from a component while resolving an instance.
  """

  alias Figler.Scene.Graph

  @doc """
  Returns the initial provenance map.

  Projected seed provenance is derivable from the node GUID, so the graph keeps
  this map sparse and records only clone/patch/variable entries that differ from
  the default projected-index provenance.
  """
  @spec initial() :: %{optional(term()) => map()}
  def initial, do: %{}

  @spec initial([term()]) :: %{optional(term()) => map()}
  def initial(_seed_nodes), do: initial()

  @doc """
  Records provenance for a node cloned while resolving an instance.
  """
  @spec put_clone(Graph.t(), term(), term(), term(), term()) :: Graph.t()
  def put_clone(%Graph{} = graph, clone_guid, source_guid, instance_guid, component_guid) do
    provenance = %{
      source: :instance_clone,
      source_guid: source_guid,
      instance_guid: instance_guid,
      component_guid: component_guid,
      applied: [],
      unresolved: []
    }

    %Graph{graph | provenance: Map.put(graph.provenance, clone_guid, provenance)}
  end
end
