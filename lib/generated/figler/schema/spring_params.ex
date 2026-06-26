defmodule Figler.Schema.SpringParams do
  @moduledoc "Generated Kiwi message module for `SpringParams`."
  use KiwiCodec, kind: :message
  field(:stiffness, 1, type: :float, source_name: "stiffness")
  field(:damping, 2, type: :float, source_name: "damping")
  field(:mass, 3, type: :float, source_name: "mass")
end
