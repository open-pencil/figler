defmodule FigKiwi.Schema.DiagramParentIndex do
  @moduledoc "Generated Kiwi struct module for `DiagramParentIndex`."
  use KiwiCodec, kind: :struct
  field(:guid, 1, type: FigKiwi.Schema.GUID, source_name: "guid")
  field(:position, 2, type: :string, source_name: "position")
end
