defmodule FigKiwi.Schema.ManagedStringNode do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.ManagedStringNodeType}, source_name: "type")

  field(:text_node_data, 2,
    type: FigKiwi.Schema.ManagedStringTextNodeData,
    source_name: "textNodeData"
  )

  field(:concatenate_node_data, 3,
    type: FigKiwi.Schema.ManagedStringConcatenateAstNodeData,
    source_name: "concatenateNodeData"
  )

  field(:plural_node_data, 4,
    type: FigKiwi.Schema.ManagedStringPluralAstNodeData,
    source_name: "pluralNodeData"
  )

  field(:placeholder_node_data, 5,
    type: FigKiwi.Schema.ManagedStringPlaceholderAstNodeData,
    source_name: "placeholderNodeData"
  )
end
