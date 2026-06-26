defmodule FigKiwi.Schema.AnnotationCategories do
  @moduledoc "Generated Kiwi message module for `AnnotationCategories`."
  use KiwiCodec, kind: :message
  field(:version, 1, type: :uint, source_name: "version")
  field(:items, 2, repeated: true, type: FigKiwi.Schema.AnnotationCategory, source_name: "items")
end
