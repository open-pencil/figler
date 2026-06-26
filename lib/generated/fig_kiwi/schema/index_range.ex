defmodule FigKiwi.Schema.IndexRange do
  @moduledoc "Generated Kiwi struct module for `IndexRange`."
  use KiwiCodec, kind: :struct
  field(:start_index, 1, type: :uint, source_name: "startIndex")
  field(:end_index_exclusive, 2, type: :uint, source_name: "endIndexExclusive")
end
