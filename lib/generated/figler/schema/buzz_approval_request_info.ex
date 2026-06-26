defmodule Figler.Schema.BuzzApprovalRequestInfo do
  @moduledoc "Generated Kiwi message module for `BuzzApprovalRequestInfo`."
  use KiwiCodec, kind: :message
  field(:request_id, 1, type: :string, source_name: "requestId")
  field(:requester_user_id, 2, type: :string, source_name: "requesterUserId")
  field(:requested_at, 3, type: :uint, source_name: "requestedAt")
  field(:reviewer_user_ids, 4, repeated: true, type: :string, source_name: "reviewerUserIds")
  field(:title, 5, type: :string, source_name: "title")
  field(:note, 6, type: :string, source_name: "note")

  field(:assets_in_request, 7,
    repeated: true,
    type: Figler.Schema.GUID,
    source_name: "assetsInRequest"
  )
end
