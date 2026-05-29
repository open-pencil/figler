defmodule FigKiwi.Schema.ComponentPropRef do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:node_field, 1, type: :uint, source_name: "nodeField")
  field(:def_id, 2, type: FigKiwi.Schema.GUID, source_name: "defID")
  field(:zombie_fallback_name, 3, type: :string, source_name: "zombieFallbackName")

  field(:component_prop_node_field, 4,
    type: {:enum, FigKiwi.Schema.ComponentPropNodeField},
    source_name: "componentPropNodeField"
  )

  field(:is_deleted, 5, type: :bool, source_name: "isDeleted")
end
