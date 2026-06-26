defmodule Figler.Schema.Baseline do
  @moduledoc "Generated Kiwi message module for `Baseline`."
  use KiwiCodec, kind: :message
  field(:position, 1, type: Figler.Schema.Vector, source_name: "position")
  field(:width, 2, type: :float, source_name: "width")
  field(:line_y, 3, type: :float, source_name: "lineY")
  field(:line_height, 4, type: :float, source_name: "lineHeight")
  field(:line_ascent, 7, type: :float, source_name: "lineAscent")
  field(:ignore_leading_trim, 8, type: :float, source_name: "ignoreLeadingTrim")
  field(:first_character, 5, type: :uint, source_name: "firstCharacter")
  field(:end_character, 6, type: :uint, source_name: "endCharacter")
end
