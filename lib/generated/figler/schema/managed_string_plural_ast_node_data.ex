defmodule Figler.Schema.ManagedStringPluralAstNodeData do
  @moduledoc "Generated Kiwi message module for `ManagedStringPluralAstNodeData`."
  use KiwiCodec, kind: :message
  field(:identifier, 1, type: :string, source_name: "identifier")

  field(:conditions, 2,
    repeated: true,
    type: Figler.Schema.ManagedStringPluralTypeMapEntry,
    source_name: "conditions"
  )
end
