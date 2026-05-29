defmodule FigKiwi.Schema.CMSItemPageTarget do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: FigKiwi.Schema.GUID, source_name: "nodeId")
  field(:cms_item_id, 2, type: :string, source_name: "cmsItemId")
  field(:field_schema_id, 3, type: :string, source_name: "fieldSchemaId")
end
