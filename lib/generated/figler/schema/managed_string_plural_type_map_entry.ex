defmodule Figler.Schema.ManagedStringPluralTypeMapEntry do
  @moduledoc "Generated Kiwi message module for `ManagedStringPluralTypeMapEntry`."
  use KiwiCodec, kind: :message
  field(:key, 1, type: {:enum, Figler.Schema.ManagedStringPluralType}, source_name: "key")
  field(:value, 2, type: Figler.Schema.ManagedStringNode, source_name: "value")
end
