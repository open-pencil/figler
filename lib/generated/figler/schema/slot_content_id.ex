defmodule Figler.Schema.SlotContentId do
  @moduledoc "Generated Kiwi message module for `SlotContentId`."
  use KiwiCodec, kind: :message
  field(:guid, 1, type: Figler.Schema.GUID, source_name: "guid")
end
