defmodule FigKiwi.Schema.MentionSource do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:default, 0)
  enum_value(:copy_duplicate, 1)
  enum_value(:silent_insert, 2)
end
