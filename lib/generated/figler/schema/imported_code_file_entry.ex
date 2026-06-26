defmodule Figler.Schema.ImportedCodeFileEntry do
  @moduledoc "Generated Kiwi message module for `ImportedCodeFileEntry`."
  use KiwiCodec, kind: :message
  field(:code_file_id, 1, type: Figler.Schema.CodeFileId, source_name: "codeFileId")
end
