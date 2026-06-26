defmodule Figler.Schema.Transform3d do
  @moduledoc "Generated Kiwi message module for `Transform3d`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.TransformSchemaType}, source_name: "type")
  field(:value, 2, type: Figler.Schema.TransformSchemaValue, source_name: "value")
  field(:backface_hidden, 3, type: :bool, source_name: "backfaceHidden")
end
