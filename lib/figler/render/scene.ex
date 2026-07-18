defmodule Figler.Render.Scene do
  @moduledoc """
  Rendering-neutral `.fig` scene prepared from generated schema data and the
  effective Figler graph.

  The effective graph owns instance semantics during preparation. `source_nodes`
  retains normalized projection metadata for inspection, while `render_nodes`
  and `children` form the rendering-neutral tree consumed by backends.
  """

  alias Figler.Scene.Graph

  @enforce_keys [:document, :payload, :graph, :root, :children, :source_nodes, :render_nodes]
  defstruct [:document, :payload, :graph, :root, :children, :source_nodes, :render_nodes]

  @type t :: %__MODULE__{
          document: Figler.Document.t(),
          payload: binary(),
          graph: Graph.t(),
          root: Graph.GUID.figma_guid(),
          children: %{optional(Graph.GUID.graph_guid()) => [Graph.GUID.graph_guid()]},
          source_nodes: %{optional(Graph.GUID.figma_guid()) => Figler.Render.SourceNode.t()},
          render_nodes: %{optional(Graph.GUID.graph_guid()) => Figler.Render.Node.t()}
        }
end
