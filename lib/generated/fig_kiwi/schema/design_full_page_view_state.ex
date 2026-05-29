defmodule FigKiwi.Schema.DesignFullPageViewState do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:design_system, 1)
  enum_value(:variables, 2)
end
