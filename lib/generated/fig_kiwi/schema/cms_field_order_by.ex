defmodule FigKiwi.Schema.CMSFieldOrderBy do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:ascending, 0)
  enum_value(:descending, 1)
end
