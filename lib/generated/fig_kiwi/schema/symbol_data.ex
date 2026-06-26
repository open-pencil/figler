defmodule FigKiwi.Schema.SymbolData do
  @moduledoc "Generated Kiwi message module for `SymbolData`."
  use KiwiCodec, kind: :message
  field(:symbol_id, 1, type: FigKiwi.Schema.GUID, source_name: "symbolID")

  field(:symbol_overrides, 2,
    repeated: true,
    type: FigKiwi.Schema.NodeChange,
    source_name: "symbolOverrides"
  )

  field(:uniform_scale_factor, 3, type: :float, source_name: "uniformScaleFactor")
end
