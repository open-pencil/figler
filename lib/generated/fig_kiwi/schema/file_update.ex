defmodule FigKiwi.Schema.FileUpdate do
  @moduledoc "Generated Kiwi message module for `FileUpdate`."
  use KiwiCodec, kind: :message
  field(:name, 1, type: :string, source_name: "name")
  field(:contents, 2, type: :string, source_name: "contents")
  field(:is_deleted, 3, type: :bool, source_name: "isDeleted")
end
