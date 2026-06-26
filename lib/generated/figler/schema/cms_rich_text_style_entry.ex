defmodule Figler.Schema.CMSRichTextStyleEntry do
  @moduledoc "Generated Kiwi message module for `CMSRichTextStyleEntry`."
  use KiwiCodec, kind: :message

  field(:style_class, 1,
    type: {:enum, Figler.Schema.CMSRichTextStyleClass},
    source_name: "styleClass"
  )

  field(:text_descriptor, 2,
    type: Figler.Schema.CMSRichTextDescriptor,
    source_name: "textDescriptor"
  )
end
