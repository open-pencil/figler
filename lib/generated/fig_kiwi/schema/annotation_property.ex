defmodule FigKiwi.Schema.AnnotationProperty do
  @moduledoc "Generated Kiwi message module for `AnnotationProperty`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.AnnotationPropertyType}, source_name: "type")
end
