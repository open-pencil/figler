defmodule FigKiwi.Schema.ManagedStringData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:key, 1, type: :string, source_name: "key")
  field(:context, 2, type: :string, source_name: "context")
  field(:locale, 3, type: :string, source_name: "locale")
  field(:content, 4, type: FigKiwi.Schema.ManagedStringNode, source_name: "content")

  field(:content_schema, 5,
    type: {:enum, FigKiwi.Schema.ManagedStringContentSchema},
    source_name: "contentSchema"
  )
end
