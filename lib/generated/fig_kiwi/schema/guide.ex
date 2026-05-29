defmodule FigKiwi.Schema.Guide do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:axis, 1, type: {:enum, FigKiwi.Schema.Axis}, source_name: "axis")
  field(:offset, 2, type: :float, source_name: "offset")
  field(:guid, 3, type: FigKiwi.Schema.GUID, source_name: "guid")
end
