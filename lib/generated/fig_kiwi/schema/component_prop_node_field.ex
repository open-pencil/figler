defmodule FigKiwi.Schema.ComponentPropNodeField do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:visible, 0)
  enum_value(:text_data, 1)
  enum_value(:overridden_symbol_id, 2)
  enum_value(:inherit_fill_style_id, 3)
  enum_value(:slot_content_id, 4)
end
