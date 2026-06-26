defmodule Figler.Schema.NodeContentsKeyframeBindingLocation do
  @moduledoc "Generated Kiwi message module for `NodeContentsKeyframeBindingLocation`."
  use KiwiCodec, kind: :message

  field(:top_level_field, 1,
    type: {:enum, Figler.Schema.TransitionOverrideBindingTopLevelField},
    source_name: "topLevelField"
  )

  field(:parameter_field_value, 2,
    type: {:enum, Figler.Schema.VariableField},
    source_name: "parameterFieldValue"
  )

  field(:index, 3, type: :int, source_name: "index")

  field(:effect_parametrized_field_value, 4,
    type: {:enum, Figler.Schema.KeyframeBindingEffectParametrizedField},
    source_name: "effectParametrizedFieldValue"
  )
end
