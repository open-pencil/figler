defmodule Figler.Schema.ManagedStringConcatenateAstNodeData do
  @moduledoc "Generated Kiwi message module for `ManagedStringConcatenateAstNodeData`."
  use KiwiCodec, kind: :message
  field(:values, 1, repeated: true, type: Figler.Schema.ManagedStringNode, source_name: "values")
end
