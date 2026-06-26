defmodule Figler.Schema.TransitionOverrideBindingLocation do
  @moduledoc "Generated Kiwi message module for `TransitionOverrideBindingLocation`."
  use KiwiCodec, kind: :message

  field(:top_level_field, 1,
    type: {:enum, Figler.Schema.TransitionOverrideBindingTopLevelField},
    source_name: "topLevelField"
  )

  field(:parameter_field_value, 2, type: :int, source_name: "parameterFieldValue")
  field(:index, 3, type: :int, source_name: "index")

  field(:effect_parametrized_field_value, 4,
    type: :int,
    source_name: "effectParametrizedFieldValue"
  )
end
