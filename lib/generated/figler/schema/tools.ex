defmodule Figler.Schema.Tools do
  @moduledoc "Generated Kiwi message module for `Tools`."
  use KiwiCodec, kind: :message
  field(:tools, 1, repeated: true, type: Figler.Schema.ToolData, source_name: "tools")
end
