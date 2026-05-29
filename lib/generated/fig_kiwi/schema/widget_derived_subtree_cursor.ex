defmodule FigKiwi.Schema.WidgetDerivedSubtreeCursor do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:session_id, 1, type: :uint, source_name: "sessionID")
  field(:counter, 2, type: :uint, source_name: "counter")
end
