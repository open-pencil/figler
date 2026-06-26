defmodule Figler.Schema.GUIDMapping do
  @moduledoc "Generated Kiwi struct module for `GUIDMapping`."
  use KiwiCodec, kind: :struct
  field(:from, 1, type: Figler.Schema.GUID, source_name: "from")
  field(:to, 2, type: Figler.Schema.GUID, source_name: "to")
end
