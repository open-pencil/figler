defmodule Figler.Schema.SharedSymbolReference do
  @moduledoc "Generated Kiwi message module for `SharedSymbolReference`."
  use KiwiCodec, kind: :message
  field(:file_key, 1, type: :string, source_name: "fileKey")
  field(:symbol_id, 2, type: Figler.Schema.GUID, source_name: "symbolID")
  field(:version_hash, 3, type: :string, source_name: "versionHash")

  field(:guid_path_mappings, 4,
    repeated: true,
    type: Figler.Schema.GUIDPathMapping,
    source_name: "guidPathMappings"
  )

  field(:bytes, 5, repeated: true, type: :byte, source_name: "bytes")

  field(:library_guid_to_subscribing_guid, 6,
    repeated: true,
    type: Figler.Schema.GUIDMapping,
    source_name: "libraryGUIDToSubscribingGUID"
  )

  field(:component_key, 7, type: :string, source_name: "componentKey")

  field(:unflattening_mappings, 8,
    repeated: true,
    type: Figler.Schema.GUIDPathMapping,
    source_name: "unflatteningMappings"
  )

  field(:is_unflattened, 9, type: :bool, source_name: "isUnflattened")
end
