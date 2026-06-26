defmodule FigKiwi.Schema.ARIAAttributeAnyValue do
  @moduledoc "Generated Kiwi message module for `ARIAAttributeAnyValue`."
  use KiwiCodec, kind: :message
  field(:bool_value, 1, type: :bool, source_name: "boolValue")
  field(:string_value, 2, type: :string, source_name: "stringValue")
  field(:float_value, 3, type: :float, source_name: "floatValue")
  field(:int_value, 4, type: :int, source_name: "intValue")
  field(:string_array_value, 5, repeated: true, type: :string, source_name: "stringArrayValue")
end
