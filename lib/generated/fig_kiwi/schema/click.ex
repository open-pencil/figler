defmodule FigKiwi.Schema.Click do
  @moduledoc "Generated Kiwi struct module for `Click`."
  use KiwiCodec, kind: :struct
  field(:id, 1, type: :uint, source_name: "id")
  field(:point, 2, type: FigKiwi.Schema.Vector, source_name: "point")
end
