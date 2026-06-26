defmodule FigKiwi.Schema.DerivedImmutableFrameData do
  @moduledoc "Generated Kiwi message module for `DerivedImmutableFrameData`."
  use KiwiCodec, kind: :message
  field(:overrides, 1, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
  field(:version, 2, type: :uint, source_name: "version")
end
