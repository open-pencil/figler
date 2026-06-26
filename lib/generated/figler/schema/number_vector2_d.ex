defmodule Figler.Schema.NumberVector2D do
  @moduledoc "Generated Kiwi struct module for `NumberVector2D`."
  use KiwiCodec, kind: :struct
  field(:x, 1, type: Figler.Schema.Number, source_name: "x")
  field(:y, 2, type: Figler.Schema.Number, source_name: "y")
end
