defmodule FigKiwi.Scene.Graph.Target do
  @moduledoc """
  Symbol override target resolution.

  Figma override paths point at source component nodes. For populated instances
  the resolver should patch the corresponding cloned node, not the source node.
  This module validates source paths when possible and resolves them through the
  graph clone index.
  """

  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID

  @type resolution :: {:ok, GUID.graph_guid()} | {:error, atom()}

  @doc """
  Resolves an override `guid_path` for an instance/source node.
  """
  @spec resolve(Graph.t(), GUID.graph_guid(), [GUID.figma_guid()]) :: resolution()
  def resolve(_graph, _instance_guid, []), do: {:error, :empty_path}

  def resolve(%Graph{} = graph, instance_guid, guid_path) do
    with :ok <- validate_source_path(graph, guid_path),
         source_guid when not is_nil(source_guid) <- List.last(guid_path) do
      resolve_source_guid(graph, instance_guid, source_guid)
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :empty_path}
    end
  end

  @doc """
  Returns `:ok` when `guid_path` is a valid parent/child path in the source graph.

  Single-segment paths are accepted if the source node exists; multi-segment
  paths must follow `graph.children` exactly.
  """
  @spec validate_source_path(Graph.t(), [GUID.figma_guid()]) :: :ok | {:error, atom()}
  def validate_source_path(_graph, []), do: {:error, :empty_path}

  def validate_source_path(graph, [guid]) do
    if Map.has_key?(graph.nodes, guid), do: :ok, else: {:error, :missing_source}
  end

  def validate_source_path(graph, [parent, child | rest]) do
    cond do
      not Map.has_key?(graph.nodes, parent) ->
        {:error, :missing_source}

      child not in Map.get(graph.children, parent, []) ->
        {:error, :invalid_path}

      true ->
        validate_source_path(graph, [child | rest])
    end
  end

  defp resolve_source_guid(graph, instance_guid, source_guid) do
    cond do
      clone_guid = Map.get(graph.clone_index, {GUID.root(instance_guid), source_guid}) ->
        {:ok, clone_guid}

      Map.has_key?(graph.nodes, source_guid) ->
        {:ok, source_guid}

      true ->
        {:error, :missing_source}
    end
  end
end
