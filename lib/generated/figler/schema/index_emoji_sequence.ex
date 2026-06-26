defmodule Figler.Schema.IndexEmojiSequence do
  @moduledoc "Generated Kiwi struct module for `IndexEmojiSequence`."
  use KiwiCodec, kind: :struct
  field(:codepoints, 1, repeated: true, type: :uint, source_name: "codepoints")
end
