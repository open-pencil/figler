defmodule Figler.Schema.ManagedStringData do
  @moduledoc "Generated Kiwi message module for `ManagedStringData`."
  use KiwiCodec, kind: :message
  field(:key, 1, type: :string, source_name: "key")
  field(:context, 2, type: :string, source_name: "context")
  field(:locale, 3, type: :string, source_name: "locale")
  field(:content, 4, type: Figler.Schema.ManagedStringNode, source_name: "content")

  field(:content_schema, 5,
    type: {:enum, Figler.Schema.ManagedStringContentSchema},
    source_name: "contentSchema"
  )
end
