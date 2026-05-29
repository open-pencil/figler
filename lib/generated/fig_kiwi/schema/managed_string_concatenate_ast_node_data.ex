defmodule FigKiwi.Schema.ManagedStringConcatenateAstNodeData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:values, 1, repeated: true, type: FigKiwi.Schema.ManagedStringNode, source_name: "values")
end
