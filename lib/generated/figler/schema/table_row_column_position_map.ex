defmodule Figler.Schema.TableRowColumnPositionMap do
  @moduledoc "Generated Kiwi message module for `TableRowColumnPositionMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: Figler.Schema.TableRowColumnPositionMapEntry,
    source_name: "entries"
  )
end
