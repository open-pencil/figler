defmodule FigKiwi.Schema.IndexEmojis do
  @moduledoc false
  use KiwiCodec, kind: :struct
  field(:revision, 1, type: :uint, source_name: "revision")
  field(:sizes, 2, repeated: true, type: :uint, source_name: "sizes")

  field(:sequences, 3,
    repeated: true,
    type: FigKiwi.Schema.IndexEmojiSequence,
    source_name: "sequences"
  )
end
