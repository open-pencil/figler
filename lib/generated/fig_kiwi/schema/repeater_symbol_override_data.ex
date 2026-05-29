defmodule FigKiwi.Schema.RepeaterSymbolOverrideData do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:overrides_by_position, 1,
    repeated: true,
    type: FigKiwi.Schema.RepeaterPositionOverrides,
    source_name: "overridesByPosition"
  )
end
