defmodule Figler.Schema.ARIAAttributeData do
  @moduledoc "Generated Kiwi message module for `ARIAAttributeData`."
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, Figler.Schema.ARIAAttributeDataType}, source_name: "type")
  field(:value, 2, type: Figler.Schema.ARIAAttributeAnyValue, source_name: "value")
end
