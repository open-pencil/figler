defmodule Figler.Schema.RepeaterPositionOverrides do
  @moduledoc "Generated Kiwi message module for `RepeaterPositionOverrides`."
  use KiwiCodec, kind: :message
  field(:position, 1, type: Figler.Schema.ParentIndex, source_name: "position")
  field(:overrides, 2, repeated: true, type: Figler.Schema.NodeChange, source_name: "overrides")
end
