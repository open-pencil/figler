defmodule FigKiwi.Schema.GUIDAndEncodedOffset do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:offset, 2, type: :uint, source_name: "offset")
end
