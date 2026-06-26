defmodule Figler.Schema.TransformModifier do
  @moduledoc "Generated Kiwi message module for `TransformModifier`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.TransformModifierType}, source_name: "type")
  field(:offset, 2, type: Figler.Schema.Vector, source_name: "offset")
  field(:visible, 3, type: :bool, source_name: "visible")
  field(:count, 4, type: :uint, source_name: "count")
  field(:repeat_type, 5, type: {:enum, Figler.Schema.RepeatType}, source_name: "repeatType")
  field(:axis, 6, type: {:enum, Figler.Schema.EffectAxis}, source_name: "axis")
  field(:unit_type, 7, type: {:enum, Figler.Schema.UnitType}, source_name: "unitType")
  field(:order, 8, type: {:enum, Figler.Schema.RepeatOrder}, source_name: "order")
  field(:skew_x, 9, type: :float, source_name: "skewX")
  field(:skew_y, 10, type: :float, source_name: "skewY")
end
