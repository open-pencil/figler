defmodule Figler.Schema.BuzzApprovalNodeStatusInfo do
  @moduledoc "Generated Kiwi message module for `BuzzApprovalNodeStatusInfo`."
  use KiwiCodec, kind: :message

  field(:current_status, 1,
    type: {:enum, Figler.Schema.BuzzApprovalNodeStatus},
    source_name: "currentStatus"
  )

  field(:was_previously_approved, 2, type: :bool, source_name: "wasPreviouslyApproved")

  field(:approval_revoked_at_history, 3,
    repeated: true,
    type: :uint,
    source_name: "approvalRevokedAtHistory"
  )
end
