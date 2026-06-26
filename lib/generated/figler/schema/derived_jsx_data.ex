defmodule Figler.Schema.DerivedJsxData do
  @moduledoc "Generated Kiwi message module for `DerivedJsxData`."
  use KiwiCodec, kind: :message
  field(:overrides, 1, repeated: true, type: Figler.Schema.NodeChange, source_name: "overrides")
end
