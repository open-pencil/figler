defmodule FigKiwi.Schema.PlatformShapeBehaviorType do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:shape, 0)
  enum_value(:container, 1)
  enum_value(:advanced_container, 2)
end
