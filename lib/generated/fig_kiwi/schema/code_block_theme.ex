defmodule FigKiwi.Schema.CodeBlockTheme do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:figjam_dark, 0)
  enum_value(:dracula, 1)
  enum_value(:duotone_sea, 2)
  enum_value(:duotone_space, 3)
  enum_value(:duotone_earth, 4)
  enum_value(:duotone_forest, 5)
  enum_value(:duotone_light, 6)
end
