defmodule FigKiwi.Schema.Transform3d do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.TransformSchemaType}, source_name: "type")
  field(:value, 2, type: FigKiwi.Schema.TransformSchemaValue, source_name: "value")
  field(:backface_hidden, 3, type: :bool, source_name: "backfaceHidden")
end
