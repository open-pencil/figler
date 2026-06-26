defmodule FigKiwi.Schema.PartialPasteAnnotation do
  @moduledoc "Generated Kiwi message module for `PartialPasteAnnotation`."
  use KiwiCodec, kind: :message
  field(:is_partial, 1, type: :bool, source_name: "isPartial")
  field(:annotated_at, 2, type: :uint64, source_name: "annotatedAt")
  field(:error_state, 3, type: {:enum, FigKiwi.Schema.BackfillError}, source_name: "errorState")
end
