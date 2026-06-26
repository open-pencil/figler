defmodule Figler.Schema.SectionPresetInfo do
  @moduledoc "Generated Kiwi message module for `SectionPresetInfo`."
  use KiwiCodec, kind: :message
  field(:shelf_id, 1, type: :uint64, source_name: "shelfId")
  field(:template_id, 2, type: :uint64, source_name: "templateId")
  field(:template_name, 3, type: :string, source_name: "templateName")
  field(:state, 4, type: {:enum, Figler.Schema.SectionPresetState}, source_name: "state")
end
