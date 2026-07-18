defmodule Figler.Render.Scene do
  @moduledoc """
  Rendering-neutral `.fig` scene prepared from generated schema data and the
  effective Figler graph.

  The effective graph owns hierarchy and instance semantics. `source_nodes`
  retains normalized source metadata, while `render_nodes` applies effective
  instance overrides and is the only node metadata consumed by backends.
  """

  alias Figler.Scene.Graph

  @enforce_keys [:document, :payload, :graph, :root, :source_nodes, :render_nodes]
  defstruct [:document, :payload, :graph, :root, :source_nodes, :render_nodes]

  @type t :: %__MODULE__{
          document: Figler.Document.t(),
          payload: binary(),
          graph: Graph.t(),
          root: Graph.GUID.figma_guid(),
          source_nodes: %{optional(Graph.GUID.figma_guid()) => Figler.Render.SourceNode.t()},
          render_nodes: %{optional(Graph.GUID.graph_guid()) => Figler.Render.SourceNode.t()}
        }
end
