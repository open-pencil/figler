defmodule FigKiwi.Schema.TableRowColumnPositionMapEntry do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:position, 2, type: :string, source_name: "position")
end
