defmodule Figler.Render.Scene do
  @moduledoc """
  Rendering-neutral `.fig` scene prepared from generated schema data and the
  effective Figler graph.

  The effective graph owns hierarchy and instance semantics. `source_nodes`
  retains only root-focused paint and shape metadata used by rendering backends.
  """

  alias Figler.Scene.Graph

  @enforce_keys [:document, :payload, :graph, :root, :source_nodes]
  defstruct [:document, :payload, :graph, :root, :source_nodes]

  @type t :: %__MODULE__{
          document: Figler.Document.t(),
          payload: binary(),
          graph: Graph.t(),
          root: Graph.GUID.figma_guid(),
          source_nodes: %{optional(Graph.GUID.figma_guid()) => Figler.Render.SourceNode.t()}
        }
end
