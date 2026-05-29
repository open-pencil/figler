defmodule FigKiwi.Schema.SourceDirectionality do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:auto, 0)
  enum_value(:ltr, 1)
  enum_value(:rtl, 2)
end
