defmodule FigKiwi.Schema.SectionPresetInfo do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:shelf_id, 1, type: :uint64, source_name: "shelfId")
  field(:template_id, 2, type: :uint64, source_name: "templateId")
  field(:template_name, 3, type: :string, source_name: "templateName")
  field(:state, 4, type: {:enum, FigKiwi.Schema.SectionPresetState}, source_name: "state")
end
