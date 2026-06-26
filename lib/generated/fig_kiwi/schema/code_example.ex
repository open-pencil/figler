defmodule FigKiwi.Schema.CodeExample do
  @moduledoc "Generated Kiwi message module for `CodeExample`."
  use KiwiCodec, kind: :message
  field(:example_name, 1, type: :string, source_name: "exampleName")
  field(:code_export_name, 2, type: :string, source_name: "codeExportName")
end
