defmodule Figler.Schema.DeveloperRelatedLink do
  @moduledoc "Generated Kiwi message module for `DeveloperRelatedLink`."
  use KiwiCodec, kind: :message
  field(:node_id, 1, type: :string, source_name: "nodeId")
  field(:file_key, 2, type: :string, source_name: "fileKey")
  field(:link_name, 3, type: :string, source_name: "linkName")
  field(:link_url, 4, type: :string, source_name: "linkUrl")
end
