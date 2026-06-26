defmodule Figler.Schema.VariableMapValue do
  @moduledoc "Generated Kiwi message module for `VariableMapValue`."
  use KiwiCodec, kind: :message
  field(:key, 1, type: :string, source_name: "key")
  field(:value, 2, type: Figler.Schema.VariableData, source_name: "value")
  field(:guid_key, 3, type: Figler.Schema.GUID, source_name: "guidKey")
end
