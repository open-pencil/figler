defmodule Figler.Schema.TableRowColumnPositionMapEntry do
  @moduledoc "Generated Kiwi message module for `TableRowColumnPositionMapEntry`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.GUID, source_name: "id")
  field(:position, 2, type: :string, source_name: "position")
end
