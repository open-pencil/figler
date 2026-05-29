defmodule FigKiwi.Schema.GUIDPathMapping do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:path, 2, type: FigKiwi.Schema.GUIDPath, source_name: "path")
end
