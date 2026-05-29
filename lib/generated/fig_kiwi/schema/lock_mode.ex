defmodule FigKiwi.Schema.LockMode do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:all, 1)
  enum_value(:background_only, 2)
end
