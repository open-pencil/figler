defmodule Figler.Schema.GUIDPathMapping do
  @moduledoc "Generated Kiwi message module for `GUIDPathMapping`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:path, 2, type: Figler.Schema.GUIDPath, source_name: "path")
end
