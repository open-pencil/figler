defmodule FigKiwi.Schema.Annotation do
  @moduledoc "Generated Kiwi message module for `Annotation`."
  use KiwiCodec, kind: :message
  field(:label, 1, type: :string, source_name: "label")

  field(:properties, 2,
    repeated: true,
    type: FigKiwi.Schema.AnnotationProperty,
    source_name: "properties"
  )

  field(:label_v2, 3, type: :string, source_name: "labelV2")
  field(:category_id, 4, type: FigKiwi.Schema.GUID, source_name: "categoryId")
end
