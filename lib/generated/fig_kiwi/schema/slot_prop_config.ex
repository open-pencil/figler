defmodule FigKiwi.Schema.SlotPropConfig do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:stretch_child_on_insert, 1, type: :bool, source_name: "stretchChildOnInsert")
  field(:display_by_default, 2, type: :bool, source_name: "displayByDefault")
  field(:min_children, 3, type: :uint, source_name: "minChildren")
  field(:max_children, 4, type: :uint, source_name: "maxChildren")
  field(:allow_preferred_values_only, 5, type: :bool, source_name: "allowPreferredValuesOnly")
end
