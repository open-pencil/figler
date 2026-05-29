defmodule FigKiwi.Schema.TextDecorationStyle do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:solid, 0)
  enum_value(:dotted, 1)
  enum_value(:wavy, 2)
end
