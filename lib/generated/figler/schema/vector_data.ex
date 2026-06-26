defmodule Figler.Schema.VectorData do
  @moduledoc "Generated Kiwi message module for `VectorData`."
  use KiwiCodec, kind: :message
  field(:vector_network_blob, 1, type: :uint, source_name: "vectorNetworkBlob")
  field(:normalized_size, 2, type: Figler.Schema.Vector, source_name: "normalizedSize")

  field(:style_override_table, 3,
    repeated: true,
    type: Figler.Schema.NodeChange,
    source_name: "styleOverrideTable"
  )
end
