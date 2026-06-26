defmodule Figler.Schema.ManagedStringNode do
  @moduledoc "Generated Kiwi message module for `ManagedStringNode`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.ManagedStringNodeType}, source_name: "type")

  field(:text_node_data, 2,
    type: Figler.Schema.ManagedStringTextNodeData,
    source_name: "textNodeData"
  )

  field(:concatenate_node_data, 3,
    type: Figler.Schema.ManagedStringConcatenateAstNodeData,
    source_name: "concatenateNodeData"
  )

  field(:plural_node_data, 4,
    type: Figler.Schema.ManagedStringPluralAstNodeData,
    source_name: "pluralNodeData"
  )

  field(:placeholder_node_data, 5,
    type: Figler.Schema.ManagedStringPlaceholderAstNodeData,
    source_name: "placeholderNodeData"
  )
end
