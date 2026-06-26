defmodule Figler.Schema.TransitionOverridePropMapEntry do
  @moduledoc "Generated Kiwi message module for `TransitionOverridePropMapEntry`."
  use KiwiCodec, kind: :message
  field(:prop, 1, type: {:enum, Figler.Schema.TransitionOverrideProp}, source_name: "prop")

  field(:overrides, 2,
    repeated: true,
    type: Figler.Schema.TransitionOverride,
    source_name: "overrides"
  )

  field(:binding_location, 3,
    type: Figler.Schema.TransitionOverrideBindingLocation,
    source_name: "bindingLocation"
  )

  field(:node_contents_binding_location, 4,
    type: Figler.Schema.NodeContentsKeyframeBindingLocation,
    source_name: "nodeContentsBindingLocation"
  )
end
