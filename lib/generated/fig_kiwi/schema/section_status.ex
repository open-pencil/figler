defmodule FigKiwi.Schema.SectionStatus do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:build, 1)
  enum_value(:completed, 2)
end
