defmodule Figler.Schema.TextLineData do
  @moduledoc "Generated Kiwi message module for `TextLineData`."
  use KiwiCodec, kind: :message
  field(:line_type, 1, type: {:enum, Figler.Schema.LineType}, source_name: "lineType")
  field(:style_id, 10, type: :int, source_name: "styleId")
  field(:indentation_level, 2, type: :int, source_name: "indentationLevel")

  field(:source_directionality, 9,
    type: {:enum, Figler.Schema.SourceDirectionality},
    source_name: "sourceDirectionality"
  )

  field(:directionality, 3,
    type: {:enum, Figler.Schema.Directionality},
    source_name: "directionality"
  )

  field(:directionality_intent, 4,
    type: {:enum, Figler.Schema.DirectionalityIntent},
    source_name: "directionalityIntent"
  )

  field(:downgrade_style_id, 5, type: :int, source_name: "downgradeStyleId")
  field(:consistency_style_id, 6, type: :int, source_name: "consistencyStyleId")
  field(:list_start_offset, 7, type: :int, source_name: "listStartOffset")
  field(:is_first_line_of_list, 8, type: :bool, source_name: "isFirstLineOfList")
end
