defmodule Figler.Schema.EditScope do
  @moduledoc "Generated Kiwi message module for `EditScope`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.EditScopeType}, source_name: "type")
  field(:label, 2, type: :string, source_name: "label")
  field(:editor_type, 3, type: {:enum, Figler.Schema.EditorType}, source_name: "editorType")
end
