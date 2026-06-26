defmodule FigKiwi.Schema.RepeaterCmsOverrideData do
  @moduledoc "Generated Kiwi message module for `RepeaterCmsOverrideData`."
  use KiwiCodec, kind: :message
  field(:overrides, 1, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
end
