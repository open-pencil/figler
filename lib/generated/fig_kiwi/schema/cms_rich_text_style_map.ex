defmodule FigKiwi.Schema.CMSRichTextStyleMap do
  @moduledoc "Generated Kiwi message module for `CMSRichTextStyleMap`."
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.CMSRichTextStyleEntry,
    source_name: "entries"
  )
end
