defmodule FigKiwi.Schema.GUIDPath do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:guids, 1, repeated: true, type: FigKiwi.Schema.GUID, source_name: "guids")
end
