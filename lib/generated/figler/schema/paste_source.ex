defmodule Figler.Schema.PasteSource do
  @moduledoc "Generated Kiwi message module for `PasteSource`."
  use KiwiCodec, kind: :message
  field(:src_file, 1, type: :string, source_name: "srcFile")
  field(:src_node, 2, type: Figler.Schema.GUID, source_name: "srcNode")
end
