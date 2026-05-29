defmodule FigKiwi.Schema.DiffType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:branching, 0)
  enum_value(:node_changes_only, 1)
end
