defmodule FigKiwi.Schema.SpringParams do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:stiffness, 1, type: :float, source_name: "stiffness")
  field(:damping, 2, type: :float, source_name: "damping")
  field(:mass, 3, type: :float, source_name: "mass")
end
