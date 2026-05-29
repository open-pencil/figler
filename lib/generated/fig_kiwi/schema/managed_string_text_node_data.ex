defmodule FigKiwi.Schema.ManagedStringTextNodeData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:value, 1, type: :string, source_name: "value")
end
