defmodule FigKiwi.Schema.JsxData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:overrides, 1, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
end
