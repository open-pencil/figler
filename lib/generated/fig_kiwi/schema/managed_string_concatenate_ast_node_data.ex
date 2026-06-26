defmodule FigKiwi.Schema.ManagedStringConcatenateAstNodeData do
  @moduledoc "Generated Kiwi message module for `ManagedStringConcatenateAstNodeData`."
  use KiwiCodec, kind: :message
  field(:values, 1, repeated: true, type: FigKiwi.Schema.ManagedStringNode, source_name: "values")
end
