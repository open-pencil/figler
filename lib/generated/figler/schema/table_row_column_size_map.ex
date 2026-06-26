defmodule Figler.Schema.TableRowColumnSizeMap do
  @moduledoc "Generated Kiwi message module for `TableRowColumnSizeMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.TableRowColumnSizeMapEntry,
    source_name: "entries"
  )
end
