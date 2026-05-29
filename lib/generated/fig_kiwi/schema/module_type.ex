defmodule FigKiwi.Schema.ModuleType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:single_node, 1)
  enum_value(:multi_node, 2)
end
