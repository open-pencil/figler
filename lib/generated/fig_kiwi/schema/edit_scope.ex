defmodule FigKiwi.Schema.EditScope do
  @moduledoc "Generated Kiwi message module for `EditScope`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.EditScopeType}, source_name: "type")
  field(:label, 2, type: :string, source_name: "label")
  field(:editor_type, 3, type: {:enum, FigKiwi.Schema.EditorType}, source_name: "editorType")
end
