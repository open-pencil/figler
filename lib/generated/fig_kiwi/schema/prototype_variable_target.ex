defmodule FigKiwi.Schema.PrototypeVariableTarget do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.VariableID, source_name: "id")
  field(:node_field_alias, 2, type: FigKiwi.Schema.NodeFieldAlias, source_name: "nodeFieldAlias")
end
