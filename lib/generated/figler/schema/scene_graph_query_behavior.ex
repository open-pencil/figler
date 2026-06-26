defmodule Figler.Schema.SceneGraphQueryBehavior do
  @moduledoc "Generated Kiwi enum module for `SceneGraphQueryBehavior`."
  use KiwiCodec, kind: :enum
  enum_value(:default, 0)
  enum_value(:containing_page, 1)
  enum_value(:plugin, 2)
end
