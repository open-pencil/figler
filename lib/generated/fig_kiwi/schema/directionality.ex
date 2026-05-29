defmodule FigKiwi.Schema.Directionality do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:ltr, 0)
  enum_value(:rtl, 1)
end
