defmodule FigKiwi.Schema.InternalEnumForTest do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:old, 1)
end
