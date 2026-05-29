defmodule FigKiwi.Schema.Blob do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:bytes, 1, repeated: true, type: :byte, source_name: "bytes")
end
