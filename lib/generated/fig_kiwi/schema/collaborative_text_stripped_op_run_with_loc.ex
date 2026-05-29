defmodule FigKiwi.Schema.CollaborativeTextStrippedOpRunWithLoc do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:type, 1, type: {:enum, FigKiwi.Schema.CollaborativeTextOpType}, source_name: "type")
  field(:range, 2, type: FigKiwi.Schema.IndexRange, source_name: "range")

  field(:range_should_be_iterated_in_reverse, 3,
    type: :bool,
    source_name: "rangeShouldBeIteratedInReverse"
  )

  field(:content_bytes_in_buffer, 4,
    type: FigKiwi.Schema.IndexRange,
    source_name: "contentBytesInBuffer"
  )

  field(:rebased_range, 5, type: FigKiwi.Schema.IndexRange, source_name: "rebasedRange")
end
