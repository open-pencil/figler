defmodule Figler.Schema.CMSRichTextDescriptor do
  @moduledoc "Generated Kiwi message module for `CMSRichTextDescriptor`."
  use KiwiCodec, kind: :message
  field(:text_style_id, 1, type: Figler.Schema.StyleId, source_name: "textStyleId")

  field(:font_name_variants, 2,
    repeated: true,
    type: Figler.Schema.FontName,
    source_name: "fontNameVariants"
  )
end
