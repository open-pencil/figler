defmodule FigKiwi.Schema.CollaborativeTextStrippedOpRunWithIDs do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:first_id, 1, type: FigKiwi.Schema.CollaborativeTextOpID, source_name: "firstId")
  field(:run_length, 2, type: :uint, source_name: "runLength")

  field(:parent_ids, 3,
    repeated: true,
    type: FigKiwi.Schema.CollaborativeTextOpID,
    source_name: "parentIds"
  )

  field(:rebased_on_op_ids, 4,
    repeated: true,
    type: FigKiwi.Schema.CollaborativeTextOpID,
    source_name: "rebasedOnOpIds"
  )
end
