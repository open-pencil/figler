defmodule Figler.Schema.TimelineAssignmentsMapEntry do
  @moduledoc "Generated Kiwi message module for `TimelineAssignmentsMapEntry`."
  use KiwiCodec, kind: :message
  field(:key, 1, type: Figler.Schema.TimelineAssignmentKey, source_name: "key")
  field(:value, 2, type: Figler.Schema.TimelineBindingData, source_name: "value")
end
