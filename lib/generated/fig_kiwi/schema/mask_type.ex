defmodule FigKiwi.Schema.MaskType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:alpha, 0)
  enum_value(:outline, 1)
  enum_value(:luminance, 2)
end
