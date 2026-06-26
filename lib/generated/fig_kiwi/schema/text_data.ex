defmodule FigKiwi.Schema.TextData do
  @moduledoc "Generated Kiwi message module for `TextData`."
  use KiwiCodec, kind: :message
  field(:characters, 1, type: :string, source_name: "characters")
  field(:character_style_i_ds, 2, repeated: true, type: :uint, source_name: "characterStyleIDs")

  field(:style_override_table, 3,
    repeated: true,
    type: FigKiwi.Schema.NodeChange,
    source_name: "styleOverrideTable"
  )

  field(:lines, 12, repeated: true, type: FigKiwi.Schema.TextLineData, source_name: "lines")
  field(:layout_version, 8, type: :uint, source_name: "layoutVersion")

  field(:fallback_fonts, 10,
    repeated: true,
    type: FigKiwi.Schema.FontName,
    source_name: "fallbackFonts"
  )

  field(:min_content_height, 17, type: :float, source_name: "minContentHeight")
  field(:layout_size, 4, type: FigKiwi.Schema.Vector, source_name: "layoutSize")
  field(:baselines, 5, repeated: true, type: FigKiwi.Schema.Baseline, source_name: "baselines")
  field(:glyphs, 6, repeated: true, type: FigKiwi.Schema.Glyph, source_name: "glyphs")

  field(:decorations, 7,
    repeated: true,
    type: FigKiwi.Schema.Decoration,
    source_name: "decorations"
  )

  field(:blockquotes, 16,
    repeated: true,
    type: FigKiwi.Schema.Blockquote,
    source_name: "blockquotes"
  )

  field(:font_meta_data, 9,
    repeated: true,
    type: FigKiwi.Schema.FontMetaData,
    source_name: "fontMetaData"
  )

  field(:hyperlink_boxes, 11,
    repeated: true,
    type: FigKiwi.Schema.HyperlinkBox,
    source_name: "hyperlinkBoxes"
  )

  field(:truncation_start_index, 13, type: :int, source_name: "truncationStartIndex")
  field(:truncated_height, 14, type: :float, source_name: "truncatedHeight")

  field(:logical_index_to_character_offset_map, 15,
    repeated: true,
    type: :float,
    source_name: "logicalIndexToCharacterOffsetMap"
  )

  field(:mention_boxes, 18,
    repeated: true,
    type: FigKiwi.Schema.MentionBox,
    source_name: "mentionBoxes"
  )

  field(:derived_lines, 19,
    repeated: true,
    type: FigKiwi.Schema.DerivedTextLineData,
    source_name: "derivedLines"
  )
end
