defmodule FigKiwi.Schema.TimelineAssignmentsMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:key, 1, type: FigKiwi.Schema.TimelineAssignmentKey, source_name: "key")
  field(:value, 2, type: FigKiwi.Schema.TimelineBindingData, source_name: "value")
end
