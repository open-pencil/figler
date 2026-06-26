defmodule Figler.Schema.SharedComponentMasterData do
  @moduledoc "Generated Kiwi message module for `SharedComponentMasterData`."
  use KiwiCodec, kind: :message
  field(:component_key, 1, type: :string, source_name: "componentKey")

  field(:publishing_guid_path_to_team_library_guid, 2,
    repeated: true,
    type: Figler.Schema.GUIDPathMapping,
    source_name: "publishingGUIDPathToTeamLibraryGUID"
  )

  field(:is_unflattened, 3, type: :bool, source_name: "isUnflattened")
end
