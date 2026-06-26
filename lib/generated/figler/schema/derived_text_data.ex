defmodule Figler.Schema.DerivedTextData do
  @moduledoc "Generated Kiwi message module for `DerivedTextData`."
  use KiwiCodec, kind: :message
  field(:layout_size, 1, type: Figler.Schema.Vector, source_name: "layoutSize")
  field(:baselines, 2, repeated: true, type: Figler.Schema.Baseline, source_name: "baselines")
  field(:glyphs, 3, repeated: true, type: Figler.Schema.Glyph, source_name: "glyphs")

  field(:decorations, 4,
    repeated: true,
    type: Figler.Schema.Decoration,
    source_name: "decorations"
  )

  field(:blockquotes, 5,
    repeated: true,
    type: Figler.Schema.Blockquote,
    source_name: "blockquotes"
  )

  field(:font_meta_data, 6,
    repeated: true,
    type: Figler.Schema.FontMetaData,
    source_name: "fontMetaData"
  )

  field(:hyperlink_boxes, 7,
    repeated: true,
    type: Figler.Schema.HyperlinkBox,
    source_name: "hyperlinkBoxes"
  )

  field(:truncation_start_index, 8, type: :int, source_name: "truncationStartIndex")
  field(:truncated_height, 9, type: :float, source_name: "truncatedHeight")

  field(:logical_index_to_character_offset_map, 10,
    repeated: true,
    type: :float,
    source_name: "logicalIndexToCharacterOffsetMap"
  )

  field(:mention_boxes, 11,
    repeated: true,
    type: Figler.Schema.MentionBox,
    source_name: "mentionBoxes"
  )

  field(:derived_lines, 12,
    repeated: true,
    type: Figler.Schema.DerivedTextLineData,
    source_name: "derivedLines"
  )
end
