defmodule FigKiwi.Schema.TableMergedCellMap do
  @moduledoc "Generated Kiwi message module for `TableMergedCellMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TableMergedCellMapEntry,
    source_name: "entries"
  )
end
