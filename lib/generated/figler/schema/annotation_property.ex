defmodule Figler.Schema.AnnotationProperty do
  @moduledoc "Generated Kiwi message module for `AnnotationProperty`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.AnnotationPropertyType}, source_name: "type")
end
