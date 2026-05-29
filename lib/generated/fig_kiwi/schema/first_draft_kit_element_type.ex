defmodule FigKiwi.Schema.FirstDraftKitElementType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:building_block, 1)
  enum_value(:grouped_component, 2)
end
