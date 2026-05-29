defmodule FigKiwi.Schema.DerivedTextData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:layout_size, 1, type: FigKiwi.Schema.Vector, source_name: "layoutSize")
  field(:baselines, 2, repeated: true, type: FigKiwi.Schema.Baseline, source_name: "baselines")
  field(:glyphs, 3, repeated: true, type: FigKiwi.Schema.Glyph, source_name: "glyphs")

  field(:decorations, 4,
    repeated: true,
    type: FigKiwi.Schema.Decoration,
    source_name: "decorations"
  )

  field(:blockquotes, 5,
    repeated: true,
    type: FigKiwi.Schema.Blockquote,
    source_name: "blockquotes"
  )

  field(:font_meta_data, 6,
    repeated: true,
    type: FigKiwi.Schema.FontMetaData,
    source_name: "fontMetaData"
  )

  field(:hyperlink_boxes, 7,
    repeated: true,
    type: FigKiwi.Schema.HyperlinkBox,
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
    type: FigKiwi.Schema.MentionBox,
    source_name: "mentionBoxes"
  )

  field(:derived_lines, 12,
    repeated: true,
    type: FigKiwi.Schema.DerivedTextLineData,
    source_name: "derivedLines"
  )
end
