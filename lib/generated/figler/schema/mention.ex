defmodule Figler.Schema.Mention do
  @moduledoc "Generated Kiwi message module for `Mention`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:mentioned_user_id, 2, type: :string, source_name: "mentionedUserId")
  field(:mentioned_by_user_id, 3, type: :string, source_name: "mentionedByUserId")
  field(:file_key, 4, type: :string, source_name: "fileKey")
  field(:source, 5, type: {:enum, Figler.Schema.MentionSource}, source_name: "source")
  field(:mentioned_user_id_int, 6, type: :uint64, source_name: "mentionedUserIdInt")
  field(:mentioned_by_user_id_int, 7, type: :uint64, source_name: "mentionedByUserIdInt")
  field(:mentioned_user_group_id, 8, type: :string, source_name: "mentionedUserGroupId")
end
