defmodule FigKiwi.Schema.KeyframeOperation do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:set, 0)
  enum_value(:scale, 1)
  enum_value(:offset, 2)
end
