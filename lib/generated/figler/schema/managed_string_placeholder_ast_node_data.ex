defmodule Figler.Schema.ManagedStringPlaceholderAstNodeData do
  @moduledoc "Generated Kiwi message module for `ManagedStringPlaceholderAstNodeData`."
  use KiwiCodec, kind: :message
  field(:identifier, 1, type: :string, source_name: "identifier")

  field(:format_type, 2,
    type: {:enum, Figler.Schema.ManagedStringFormatType},
    source_name: "formatType"
  )

  field(:format_pattern, 3, type: :string, source_name: "formatPattern")
end
