defmodule Figler.Schema.Matrix do
  @moduledoc "Generated Kiwi struct module for `Matrix`."
  use KiwiCodec, kind: :struct
  field(:m00, 1, type: :float, source_name: "m00")
  field(:m01, 2, type: :float, source_name: "m01")
  field(:m02, 3, type: :float, source_name: "m02")
  field(:m10, 4, type: :float, source_name: "m10")
  field(:m11, 5, type: :float, source_name: "m11")
  field(:m12, 6, type: :float, source_name: "m12")
end
