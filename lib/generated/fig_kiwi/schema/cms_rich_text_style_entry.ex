defmodule FigKiwi.Schema.CMSRichTextStyleEntry do
  @moduledoc "Generated Kiwi message module for `CMSRichTextStyleEntry`."
  use KiwiCodec, kind: :message

  field(:style_class, 1,
    type: {:enum, FigKiwi.Schema.CMSRichTextStyleClass},
    source_name: "styleClass"
  )

  field(:text_descriptor, 2,
    type: FigKiwi.Schema.CMSRichTextDescriptor,
    source_name: "textDescriptor"
  )
end
