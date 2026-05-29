defmodule FigKiwi.Schema.DiagramLayoutRuleType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:tree, 1)
end
