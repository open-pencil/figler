defmodule FigKiwi.Schema.ManagedStringTextNodeData do
  @moduledoc "Generated Kiwi message module for `ManagedStringTextNodeData`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: :string, source_name: "value")
end
