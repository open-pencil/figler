defmodule Figler.Schema.NodeStatusChange do
  @moduledoc "Generated Kiwi message module for `NodeStatusChange`."
  use KiwiCodec, kind: :message
  field(:node_ids, 1, repeated: true, type: Figler.Schema.GUID, source_name: "nodeIds")
  field(:status_info, 2, type: Figler.Schema.SectionStatusInfo, source_name: "statusInfo")
end
