defmodule FigKiwi.Schema.FirstDraftKitElementData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.FirstDraftKitElementType}, source_name: "type")
end
