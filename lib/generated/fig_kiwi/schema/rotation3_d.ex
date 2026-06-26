defmodule FigKiwi.Schema.Rotation3D do
  @moduledoc "Generated Kiwi message module for `Rotation3D`."
  use KiwiCodec, kind: :message
  field(:x, 1, type: :float, source_name: "x")
  field(:y, 2, type: :float, source_name: "y")
  field(:z, 3, type: :float, source_name: "z")
  field(:translate_z, 4, type: :float, source_name: "translateZ")
end
