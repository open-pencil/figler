defmodule FigKiwi.Schema.ManagedStringPlaceholderAstNodeData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:identifier, 1, type: :string, source_name: "identifier")

  field(:format_type, 2,
    type: {:enum, FigKiwi.Schema.ManagedStringFormatType},
    source_name: "formatType"
  )

  field(:format_pattern, 3, type: :string, source_name: "formatPattern")
end
