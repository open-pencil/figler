defmodule FigKiwi.Schema.ManagedStringContentSchema do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:v0, 0)
end
