defmodule Figler.Schema.EditInfo do
  @moduledoc "Generated Kiwi message module for `EditInfo`."
  use KiwiCodec, kind: :message
  field(:timestamp_iso8601, 1, type: :string, source_name: "timestampIso8601")
  field(:user_id, 2, type: :string, source_name: "userId")
  field(:last_edited_at, 3, type: :uint, source_name: "lastEditedAt")
  field(:created_at, 4, type: :uint, source_name: "createdAt")
end
