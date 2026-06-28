defmodule Figler.Scene.Graph.Provenance do
  @moduledoc """
  Builds and updates provenance metadata for resolved graph nodes.

  Provenance records explain whether a node came directly from the projected
  index or was cloned from a component while resolving an instance.
  """

  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.Seed.Node, as: SeedNode

  @doc """
  Builds initial provenance for projected seed nodes.
  """
  @spec initial([SeedNode.t()]) :: %{optional(term()) => map()}
  def initial(seed_nodes) do
    Map.new(seed_nodes, fn %SeedNode{} = seed ->
      {seed.guid,
       %{
         source: :projected_index,
         source_guid: seed.guid,
         applied: [],
         unresolved: []
       }}
    end)
  end

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
