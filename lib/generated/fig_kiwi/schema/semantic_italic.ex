defmodule FigKiwi.Schema.SemanticItalic do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:normal, 0)
  enum_value(:italic, 1)
end
