defmodule FigKiwi.Schema.SlotContentId do
  @moduledoc "Generated Kiwi message module for `SlotContentId`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
end
