defmodule Figler.Schema.CollaborativeTextOpRun do
  @moduledoc "Generated Kiwi message module for `CollaborativeTextOpRun`."
  use KiwiCodec, kind: :message
  field(:id, 1, type: Figler.Schema.CollaborativeTextOpID, source_name: "id")

  field(:parent_ids, 2,
    repeated: true,
    type: Figler.Schema.CollaborativeTextOpID,
    source_name: "parentIds"
  )

  field(:type, 3, type: {:enum, Figler.Schema.CollaborativeTextOpType}, source_name: "type")
  field(:range, 4, type: Figler.Schema.IndexRange, source_name: "range")

  field(:range_should_be_iterated_in_reverse, 5,
    type: :bool,
    source_name: "rangeShouldBeIteratedInReverse"
  )

  field(:content, 6, type: :string, source_name: "content")

  field(:rebased_on_op_ids, 7,
    repeated: true,
    type: Figler.Schema.CollaborativeTextOpID,
    source_name: "rebasedOnOpIds"
  )

  field(:rebased_range, 8, type: Figler.Schema.IndexRange, source_name: "rebasedRange")
end
