defmodule FigKiwi.Schema.CMSSelectorFilterOperator do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:equals, 0)
end
