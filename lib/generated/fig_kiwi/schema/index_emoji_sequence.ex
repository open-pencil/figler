defmodule FigKiwi.Schema.IndexEmojiSequence do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:codepoints, 1, repeated: true, type: :uint, source_name: "codepoints")
end
