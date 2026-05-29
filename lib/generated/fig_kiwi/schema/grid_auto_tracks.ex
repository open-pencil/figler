defmodule FigKiwi.Schema.GridAutoTracks do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:none, 0)
  enum_value(:rows, 1)
end
