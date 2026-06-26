defmodule FigKiwi.Schema.TableRowColumnSizeMapEntry do
  @moduledoc "Generated Kiwi message module for `TableRowColumnSizeMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:size, 2, type: :float, source_name: "size")
end
