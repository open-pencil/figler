defmodule FigKiwi.Schema.AgendaItemType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:node, 0)
  enum_value(:block, 1)
end
