defmodule FigKiwi.Schema.JsxData do
  @moduledoc "Generated Kiwi message module for `JsxData`."
  use KiwiCodec, kind: :message
  field(:overrides, 1, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
end
