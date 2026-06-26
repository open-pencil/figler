defmodule Figler.Schema.SectionStatusInfo do
  @moduledoc "Generated Kiwi message module for `SectionStatusInfo`."
  use KiwiCodec, kind: :message
  field(:status, 1, type: {:enum, Figler.Schema.SectionStatus}, source_name: "status")
  field(:last_update_unix_timestamp, 2, type: :uint, source_name: "lastUpdateUnixTimestamp")
  field(:description, 3, type: :string, source_name: "description")
  field(:user_id, 4, type: :string, source_name: "userId")
  field(:prev_status, 5, type: {:enum, Figler.Schema.SectionStatus}, source_name: "prevStatus")
end
