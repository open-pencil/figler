defmodule FigKiwi.Schema.Rotation3DConfig do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:mode, 1, type: {:enum, FigKiwi.Schema.PointMode}, source_name: "mode")
end
