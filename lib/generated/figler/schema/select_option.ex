defmodule Figler.Schema.SelectOption do
  @moduledoc "Generated Kiwi message module for `SelectOption`."
  use KiwiCodec, kind: :message
  field(:value, 1, type: Figler.Schema.VariableData, source_name: "value")
  field(:label, 2, type: :string, source_name: "label")
end
