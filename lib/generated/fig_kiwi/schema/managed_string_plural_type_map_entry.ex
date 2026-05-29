defmodule FigKiwi.Schema.ManagedStringPluralTypeMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:key, 1, type: {:enum, FigKiwi.Schema.ManagedStringPluralType}, source_name: "key")
  field(:value, 2, type: FigKiwi.Schema.ManagedStringNode, source_name: "value")
end
