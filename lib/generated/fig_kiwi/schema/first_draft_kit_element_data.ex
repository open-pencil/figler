defmodule FigKiwi.Schema.FirstDraftKitElementData do
  @moduledoc "Generated Kiwi message module for `FirstDraftKitElementData`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.FirstDraftKitElementType}, source_name: "type")
end
