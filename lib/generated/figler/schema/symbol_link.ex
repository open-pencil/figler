defmodule Figler.Schema.SymbolLink do
  @moduledoc "Generated Kiwi message module for `SymbolLink`."
  use KiwiCodec, kind: :message
  field(:uri, 1, type: :string, source_name: "uri")
  field(:display_name, 2, type: :string, source_name: "displayName")
  field(:display_text, 3, type: :string, source_name: "displayText")
end
