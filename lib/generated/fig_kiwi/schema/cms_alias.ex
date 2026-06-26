defmodule FigKiwi.Schema.CMSAlias do
  @moduledoc "Generated Kiwi message module for `CMSAlias`."
  use KiwiCodec, kind: :message
  field(:collection_id, 1, type: :string, source_name: "collectionId")
  field(:item_id, 2, type: :string, source_name: "itemId")
  field(:field_id, 3, type: :string, source_name: "fieldId")
  field(:type, 4, type: {:enum, FigKiwi.Schema.VariableDataType}, source_name: "type")
end
