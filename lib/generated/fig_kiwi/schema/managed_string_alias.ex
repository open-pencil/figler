defmodule FigKiwi.Schema.ManagedStringAlias do
  @moduledoc "Generated Kiwi message module for `ManagedStringAlias`."
  use KiwiCodec, kind: :message

  field(:managed_string_id, 1,
    type: FigKiwi.Schema.ManagedStringId,
    source_name: "managedStringId"
  )

  field(:placeholder_values, 2,
    repeated: true,
    type: FigKiwi.Schema.ManagedStringPlaceholderMapEntry,
    source_name: "placeholderValues"
  )
end
