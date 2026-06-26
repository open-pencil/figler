defmodule Figler.Schema.TransitionOverrideData do
  @moduledoc "Generated Kiwi message module for `TransitionOverrideData`."
  use KiwiCodec, kind: :message
  field(:all, 1, repeated: true, type: Figler.Schema.TransitionOverride, source_name: "all")

  field(:property_overrides, 2,
    type: Figler.Schema.TransitionOverridePropMap,
    source_name: "propertyOverrides"
  )
end
