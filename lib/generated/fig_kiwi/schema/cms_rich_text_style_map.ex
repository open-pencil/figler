defmodule FigKiwi.Schema.CMSRichTextStyleMap do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:entries, 1,
    repeated: true,
    type: FigKiwi.Schema.CMSRichTextStyleEntry,
    source_name: "entries"
  )
end
