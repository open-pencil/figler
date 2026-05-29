defmodule FigKiwi.Schema.DashMode do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:clip, 0)
  enum_value(:stretch, 1)
end
