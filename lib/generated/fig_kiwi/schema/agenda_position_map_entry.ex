defmodule FigKiwi.Schema.AgendaPositionMapEntry do
  @moduledoc "Generated Kiwi message module for `AgendaPositionMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: FigKiwi.Schema.GUID, source_name: "id")
  field(:position, 2, type: :string, source_name: "position")
end
