defmodule Figler.Schema.BuzzApprovalRequests do
  @moduledoc "Generated Kiwi message module for `BuzzApprovalRequests`."
  use KiwiCodec, kind: :message

  field(:requests, 1,
    repeated: true,
    type: Figler.Schema.BuzzApprovalRequestInfo,
    source_name: "requests"
  )
end
