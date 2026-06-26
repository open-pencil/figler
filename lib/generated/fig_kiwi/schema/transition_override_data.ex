defmodule FigKiwi.Schema.TransitionOverrideData do
  @moduledoc "Generated Kiwi message module for `TransitionOverrideData`."
  use KiwiCodec, kind: :message
  field(:all, 1, repeated: true, type: FigKiwi.Schema.TransitionOverride, source_name: "all")

  field(:property_overrides, 2,
    type: FigKiwi.Schema.TransitionOverridePropMap,
    source_name: "propertyOverrides"
  )
end
