defmodule FigKiwi.Schema.TableRowColumnPositionMap do
  @moduledoc "Generated Kiwi message module for `TableRowColumnPositionMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TableRowColumnPositionMapEntry,
    source_name: "entries"
  )
end
