defmodule FigKiwi.Schema.CollaborativePlainText do
  @moduledoc false
  use KiwiCodec, kind: :message

  field(:history_ops_with_ids, 1,
    repeated: true,
    type: FigKiwi.Schema.CollaborativeTextStrippedOpRunWithIDs,
    source_name: "historyOpsWithIds"
  )

  field(:history_ops_with_loc, 2,
    repeated: true,
    type: FigKiwi.Schema.CollaborativeTextStrippedOpRunWithLoc,
    source_name: "historyOpsWithLoc"
  )

  field(:history_string_content_buffer, 3,
    repeated: true,
    type: :byte,
    source_name: "historyStringContentBuffer"
  )

  field(:changes_to_append, 4,
    repeated: true,
    type: FigKiwi.Schema.CollaborativeTextOpRun,
    source_name: "changesToAppend"
  )
end
