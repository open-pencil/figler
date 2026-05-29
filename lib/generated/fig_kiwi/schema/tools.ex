defmodule FigKiwi.Schema.Tools do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:tools, 1, repeated: true, type: FigKiwi.Schema.ToolData, source_name: "tools")
end
