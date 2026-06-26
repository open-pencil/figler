defmodule FigKiwi.Schema.BulletType do
  @moduledoc "Generated Kiwi enum module for `BulletType`."
  use KiwiCodec, kind: :enum
  enum_value(:ordered, 0)
  enum_value(:unordered, 1)
  enum_value(:indent, 2)
  enum_value(:no_list, 3)
end
