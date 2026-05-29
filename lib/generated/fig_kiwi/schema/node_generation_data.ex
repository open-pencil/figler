defmodule FigKiwi.Schema.NodeGenerationData do
  @moduledoc false
  use KiwiCodec, kind: :message
  field(:overrides, 1, repeated: true, type: FigKiwi.Schema.NodeChange, source_name: "overrides")
  field(:use_fine_grained_syncing, 2, type: :bool, source_name: "useFineGrainedSyncing")

  field(:diff_only_removals, 3,
    repeated: true,
    type: FigKiwi.Schema.NodeChange,
    source_name: "diffOnlyRemovals"
  )
end
