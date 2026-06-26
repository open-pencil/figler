defmodule Figler.Schema.RepeaterOverrideData do
  @moduledoc "Generated Kiwi message module for `RepeaterOverrideData`."
  use KiwiCodec, kind: :message

  field(:parent_index_overrides, 1,
    repeated: true,
    type: Figler.Schema.NodeChange,
    source_name: "parentIndexOverrides"
  )
end
