defmodule Figler.Schema.Vector do
  @moduledoc "Generated Kiwi struct module for `Vector`."
  use KiwiCodec, kind: :struct
  field(:x, 1, type: :float, source_name: "x")
  field(:y, 2, type: :float, source_name: "y")
end
