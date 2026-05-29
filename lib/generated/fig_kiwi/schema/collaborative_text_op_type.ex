defmodule FigKiwi.Schema.CollaborativeTextOpType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:insert, 0)
  enum_value(:delete, 1)
end
