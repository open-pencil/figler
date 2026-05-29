defmodule FigKiwi.Schema.SceneGraphQueryMode do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:add, 0)
  enum_value(:set, 1)
end
