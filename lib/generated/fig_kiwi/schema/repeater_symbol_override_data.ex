defmodule FigKiwi.Schema.RepeaterSymbolOverrideData do
  @moduledoc "Generated Kiwi message module for `RepeaterSymbolOverrideData`."
  use KiwiCodec, kind: :message

  field(:overrides_by_position, 1,
    repeated: true,
    type: FigKiwi.Schema.RepeaterPositionOverrides,
    source_name: "overridesByPosition"
  )
end
