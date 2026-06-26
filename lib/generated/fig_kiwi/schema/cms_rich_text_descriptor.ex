defmodule FigKiwi.Schema.CMSRichTextDescriptor do
  @moduledoc "Generated Kiwi message module for `CMSRichTextDescriptor`."
  use KiwiCodec, kind: :message
  field(:text_style_id, 1, type: FigKiwi.Schema.StyleId, source_name: "textStyleId")

  field(:font_name_variants, 2,
    repeated: true,
    type: FigKiwi.Schema.FontName,
    source_name: "fontNameVariants"
  )
end
