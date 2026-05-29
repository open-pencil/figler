defmodule FigKiwi.Schema.ScrollPosition do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:node, 1, type: FigKiwi.Schema.GUID, source_name: "node")
  field(:scroll_offset, 2, type: FigKiwi.Schema.Vector, source_name: "scrollOffset")
end
