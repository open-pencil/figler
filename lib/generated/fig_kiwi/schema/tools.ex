defmodule FigKiwi.Schema.Tools do
  @moduledoc "Generated Kiwi message module for `Tools`."
  use KiwiCodec, kind: :message
  field(:tools, 1, repeated: true, type: FigKiwi.Schema.ToolData, source_name: "tools")
end
