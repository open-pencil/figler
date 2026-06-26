defmodule FigKiwi.Schema.FirstDraftKit do
  @moduledoc "Generated Kiwi message module for `FirstDraftKit`."
  use KiwiCodec, kind: :message
  field(:key, 1, type: :string, source_name: "key")
  field(:type, 2, type: {:enum, FigKiwi.Schema.FirstDraftKitType}, source_name: "type")
end
