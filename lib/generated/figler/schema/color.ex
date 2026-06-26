defmodule Figler.Schema.Color do
  @moduledoc "Generated Kiwi struct module for `Color`."
  use KiwiCodec, kind: :struct
  field(:r, 1, type: :float, source_name: "r")
  field(:g, 2, type: :float, source_name: "g")
  field(:b, 3, type: :float, source_name: "b")
  field(:a, 4, type: :float, source_name: "a")
end
