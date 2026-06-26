defmodule FigKiwi.Schema.ParentIndex do
  @moduledoc "Generated Kiwi struct module for `ParentIndex`."
  use KiwiCodec, kind: :struct
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:position, 2, type: :string, source_name: "position")
end
