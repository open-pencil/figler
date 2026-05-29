defmodule FigKiwi.Schema.TableRowColumnPositionMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TableRowColumnPositionMapEntry,
    source_name: "entries"
  )
end
