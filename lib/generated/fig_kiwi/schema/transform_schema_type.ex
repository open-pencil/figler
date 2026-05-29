defmodule FigKiwi.Schema.TransformSchemaType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:fixed_order, 1)
  enum_value(:freeform, 2)
end
