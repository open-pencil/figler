defmodule Figler.Schema.CMSRichTextStyleClass do
  @moduledoc "Generated Kiwi enum module for `CMSRichTextStyleClass`."
  use KiwiCodec, kind: :enum
  enum_value(:heading1, 0)
  enum_value(:heading2, 1)
  enum_value(:heading3, 2)
  enum_value(:heading4, 3)
  enum_value(:heading5, 4)
  enum_value(:heading6, 5)
  enum_value(:paragraph, 6)
  enum_value(:link, 7)
  enum_value(:blockquote, 8)
end
