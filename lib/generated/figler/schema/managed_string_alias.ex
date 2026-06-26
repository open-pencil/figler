defmodule Figler.Schema.ManagedStringAlias do
  @moduledoc "Generated Kiwi message module for `ManagedStringAlias`."
  use KiwiCodec, kind: :message

  field(:managed_string_id, 1,
    type: Figler.Schema.ManagedStringId,
    source_name: "managedStringId"
  )

  field(:placeholder_values, 2,
    repeated: true,
    type: Figler.Schema.ManagedStringPlaceholderMapEntry,
    source_name: "placeholderValues"
  )
end
