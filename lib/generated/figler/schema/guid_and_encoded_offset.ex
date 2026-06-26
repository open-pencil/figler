defmodule Figler.Schema.GUIDAndEncodedOffset do
  @moduledoc "Generated Kiwi struct module for `GUIDAndEncodedOffset`."
  use KiwiCodec, kind: :struct
  field(:guid, 1, type: Figler.Schema.GUID, source_name: "guid")
  field(:offset, 2, type: :uint, source_name: "offset")
end
