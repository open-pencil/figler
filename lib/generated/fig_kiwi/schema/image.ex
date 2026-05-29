defmodule FigKiwi.Schema.Image do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:hash, 1, repeated: true, type: :byte, source_name: "hash")
  field(:name, 2, type: :string, source_name: "name")
  field(:data_blob, 3, type: :uint, source_name: "dataBlob")
end
