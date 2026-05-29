defmodule FigKiwi.Schema.AnnotationCategory do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:preset, 2, type: {:enum, FigKiwi.Schema.AnnotationCategoryPreset}, source_name: "preset")
  field(:custom, 3, type: FigKiwi.Schema.AnnotationCategoryCustom, source_name: "custom")
end
