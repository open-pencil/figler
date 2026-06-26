defmodule Figler.Schema.GUIDPositionMapEntry do
  @moduledoc "Generated Kiwi message module for `GUIDPositionMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:position, 2, type: :string, source_name: "position")
end
