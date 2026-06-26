defmodule FigKiwi.Schema.ConnectorMagnet do
  @moduledoc "Generated Kiwi enum module for `ConnectorMagnet`."
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:auto, 1)
  enum_value(:top, 2)
  enum_value(:left, 3)
  enum_value(:bottom, 4)
  enum_value(:right, 5)
  enum_value(:center, 6)
  enum_value(:auto_horizontal, 7)
  enum_value(:edge, 8)
  enum_value(:absolute, 9)
end
