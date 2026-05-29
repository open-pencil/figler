defmodule FigKiwi.Schema.ResponsiveScalingMode do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:reflow, 0)
  enum_value(:scale, 1)
end
