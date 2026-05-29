defmodule FigKiwi.Schema.SceneGraphQueryBehavior do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:default, 0)
  enum_value(:containing_page, 1)
  enum_value(:plugin, 2)
end
