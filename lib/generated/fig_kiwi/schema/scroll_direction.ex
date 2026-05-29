defmodule FigKiwi.Schema.ScrollDirection do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:horizontal, 1)
  enum_value(:vertical, 2)
  enum_value(:both, 3)
end
