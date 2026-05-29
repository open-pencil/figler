defmodule FigKiwi.Schema.ImageImportMap do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:imports, 1, repeated: true, type: FigKiwi.Schema.ImageImport, source_name: "imports")
end
