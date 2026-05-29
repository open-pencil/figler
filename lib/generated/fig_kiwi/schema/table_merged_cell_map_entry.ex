defmodule FigKiwi.Schema.TableMergedCellMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:row_id, 1, type: FigKiwi.Schema.GUID, source_name: "rowId")
  field(:col_id, 2, type: FigKiwi.Schema.GUID, source_name: "colId")
  field(:row_span, 3, type: :int, source_name: "rowSpan")
  field(:col_span, 4, type: :int, source_name: "colSpan")
end
