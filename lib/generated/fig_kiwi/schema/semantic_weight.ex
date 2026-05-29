defmodule FigKiwi.Schema.SemanticWeight do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:normal, 0)
  enum_value(:bold, 1)
end
