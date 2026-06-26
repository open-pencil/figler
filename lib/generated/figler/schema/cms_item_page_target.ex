defmodule Figler.Schema.CMSItemPageTarget do
  @moduledoc "Generated Kiwi message module for `CMSItemPageTarget`."
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: Figler.Schema.GUID, source_name: "nodeId")
  field(:cms_item_id, 2, type: :string, source_name: "cmsItemId")
  field(:field_schema_id, 3, type: :string, source_name: "fieldSchemaId")
end
