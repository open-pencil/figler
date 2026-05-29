defmodule FigKiwi.Schema.SectionPresetState do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:inserted, 0)
  enum_value(:user_edited, 1)
end
