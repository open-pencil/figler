defmodule Figler.Schema.ImageImportMap do
  @moduledoc "Generated Kiwi message module for `ImageImportMap`."
  use KiwiCodec, kind: :message
  field(:imports, 1, repeated: true, type: Figler.Schema.ImageImport, source_name: "imports")
end
