defmodule FigKiwi.Schema.Glyph do
  @moduledoc "Generated Kiwi message module for `Glyph`."
  use KiwiCodec, kind: :message
  field(:commands_blob, 1, type: :uint, source_name: "commandsBlob")
  field(:position, 2, type: FigKiwi.Schema.Vector, source_name: "position")
  field(:style_id, 3, type: :uint, source_name: "styleID")
  field(:font_size, 4, type: :float, source_name: "fontSize")
  field(:first_character, 5, type: :uint, source_name: "firstCharacter")
  field(:advance, 6, type: :float, source_name: "advance")
  field(:emoji_code_points, 7, repeated: true, type: :uint, source_name: "emojiCodePoints")

  field(:emoji_image_set, 8,
    type: {:enum, FigKiwi.Schema.EmojiImageSet},
    source_name: "emojiImageSet"
  )

  field(:rotation, 9, type: :float, source_name: "rotation")
end
