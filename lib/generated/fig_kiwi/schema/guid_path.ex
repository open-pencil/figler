defmodule FigKiwi.Schema.GUIDPath do
  @moduledoc "Generated Kiwi message module for `GUIDPath`."
  use KiwiCodec, kind: :message
  field(:guids, 1, repeated: true, type: FigKiwi.Schema.GUID, source_name: "guids")
end
