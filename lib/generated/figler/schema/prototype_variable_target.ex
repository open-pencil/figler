defmodule Figler.Schema.PrototypeVariableTarget do
  @moduledoc "Generated Kiwi message module for `PrototypeVariableTarget`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.VariableID, source_name: "id")
  field(:node_field_alias, 2, type: Figler.Schema.NodeFieldAlias, source_name: "nodeFieldAlias")
end
