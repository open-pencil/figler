defmodule FigKiwi.Schema.AnnotationCategoryPreset do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:accessibility, 1)
  enum_value(:behavior, 2)
  enum_value(:content, 3)
  enum_value(:development, 4)
  enum_value(:interaction, 5)
end
