defmodule FigKiwi.Schema.SlotContentId do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
end
