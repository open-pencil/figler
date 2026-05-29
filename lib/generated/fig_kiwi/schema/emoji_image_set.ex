defmodule FigKiwi.Schema.EmojiImageSet do
  @moduledoc false
  use KiwiCodec, kind: :enum
  enum_value(:apple, 0)
  enum_value(:noto, 1)
end
