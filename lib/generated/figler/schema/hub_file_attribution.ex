defmodule Figler.Schema.HubFileAttribution do
  @moduledoc "Generated Kiwi message module for `HubFileAttribution`."
  use KiwiCodec, kind: :message
  field(:hub_file_id, 1, type: :string, source_name: "hubFileId")
  field(:hub_file_name, 2, type: :string, source_name: "hubFileName")
end
