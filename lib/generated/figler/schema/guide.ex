defmodule Figler.Schema.Guide do
  @moduledoc "Generated Kiwi message module for `Guide`."
  use KiwiCodec, kind: :message
  field(:axis, 1, type: {:enum, Figler.Schema.Axis}, source_name: "axis")
  field(:offset, 2, type: :float, source_name: "offset")
  field(:guid, 3, type: Figler.Schema.GUID, source_name: "guid")
end
