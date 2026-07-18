defmodule Figler.Render.Scene do
  @moduledoc """
  Rendering-neutral `.fig` scene prepared from generated schema data and the
  effective Figler graph.

  The effective graph owns hierarchy and instance semantics. `source_nodes`
  retains the richer generated `NodeChange` values used by rendering backends.
  """

  alias Figler.Scene.Graph

  @enforce_keys [:payload, :message, :graph, :source_nodes]
  defstruct [:payload, :message, :graph, :source_nodes]

  @type t :: %__MODULE__{
          payload: binary(),
          message: Figler.Schema.Message.t(),
          graph: Graph.t(),
          source_nodes: %{optional(Graph.GUID.figma_guid()) => Figler.Schema.NodeChange.t()}
        }
end
