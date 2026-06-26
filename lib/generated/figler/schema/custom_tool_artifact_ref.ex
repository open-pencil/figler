defmodule Figler.Schema.CustomToolArtifactRef do
  @moduledoc "Generated Kiwi message module for `CustomToolArtifactRef`."
  use KiwiCodec, kind: :message
  field(:custom_tool_id, 1, type: :string, source_name: "customToolId")
  field(:custom_tool_version, 2, type: :string, source_name: "customToolVersion")
  field(:published_custom_tool_id, 3, type: :string, source_name: "publishedCustomToolId")

  field(:published_custom_tool_version_id, 4,
    type: :string,
    source_name: "publishedCustomToolVersionId"
  )
end
