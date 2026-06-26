defmodule FigKiwi.Schema.BuzzApprovalRequests do
  @moduledoc "Generated Kiwi message module for `BuzzApprovalRequests`."
  use KiwiCodec, kind: :message

  field(:requests, 1,
    repeated: true,
    type: FigKiwi.Schema.BuzzApprovalRequestInfo,
    source_name: "requests"
  )
end
