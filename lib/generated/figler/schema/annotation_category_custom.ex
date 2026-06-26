defmodule Figler.Schema.AnnotationCategoryCustom do
  @moduledoc "Generated Kiwi message module for `AnnotationCategoryCustom`."
  use KiwiCodec, kind: :message
  field(:color, 1, type: {:enum, Figler.Schema.AnnotationCategoryColor}, source_name: "color")
  field(:custom_color, 2, type: Figler.Schema.Color, source_name: "customColor")
  field(:label, 3, type: :string, source_name: "label")
end
