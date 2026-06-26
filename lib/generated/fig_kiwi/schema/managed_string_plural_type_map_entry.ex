defmodule FigKiwi.Schema.ManagedStringPluralTypeMapEntry do
  @moduledoc "Generated Kiwi message module for `ManagedStringPluralTypeMapEntry`."
  use KiwiCodec, kind: :message
  field(:key, 1, type: {:enum, FigKiwi.Schema.ManagedStringPluralType}, source_name: "key")
  field(:value, 2, type: FigKiwi.Schema.ManagedStringNode, source_name: "value")
end
