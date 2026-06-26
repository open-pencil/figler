defmodule Figler.Schema.WidgetPointer do
  @moduledoc "Generated Kiwi message module for `WidgetPointer`."
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: Figler.Schema.GUID, source_name: "nodeId")
end
