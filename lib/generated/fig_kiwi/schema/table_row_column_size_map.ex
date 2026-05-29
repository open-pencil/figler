defmodule FigKiwi.Schema.TableRowColumnSizeMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.TableRowColumnSizeMapEntry,
    source_name: "entries"
  )
end
